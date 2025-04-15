
--[[
MIT License
Copyright (c) 2025 sigma-axis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

https://mit-license.org/
]]

--
-- VERSION: v1.11-beta1
--

--------------------------------

local GLShaderKit = require "GLShaderKit";

local obj, math, tonumber = obj, math, tonumber;

local function error_mod(message)
	message = "InlineScene_S.lua: "..message;
	debug_print(message);
	local function err_mes()
		obj.setfont("MS UI Gothic", 42, 3);
		obj.load("text", message);
	end
	return setmetatable({}, { __index = function(...) return err_mes end });
end
if not GLShaderKit.isInitialized() then return error_mod [=[このデバイスでは GLShaderKit が利用できません!]=];
else
	local function lexical_comp(a, b, ...)
		return a == nil and 0 or a < b and -1 or a > b and 1 or lexical_comp(...);
	end
	local version = GLShaderKit.version();
	local v1, v2, v3 = version:match("^(%d+)%.(%d+)%.(%d+)$");
	v1, v2, v3 = tonumber(v1), tonumber(v2), tonumber(v3);
	-- version must be at least v0.4.0.
	if not (v1 and v2 and v3) or lexical_comp(v1, 0, v2, 4, v3, 0) < 0 then
		debug_print([=[現在の GLShaderKit のバージョン: ]=]..version);
		return error_mod [=[この GLShaderKit のバージョンでは動作しません!]=];
	end
end

-- ref: https://github.com/Mr-Ojii/AviUtl-RotBlur_M-Script/blob/main/script/RotBlur_M.lua
local function script_path()
    return debug.getinfo(1).source:match("@?(.*[/\\])");
end
local shader_path = script_path().."RadRotDirBlur_S.frag";

-- calculation of bounding boxes.
local function union_rect(l, t, r, b, L, T, R, B)
	return math.min(l, L), math.min(t, T), math.max(r, R), math.max(b, B);
end
local function arc_bound_core2(R, A, a, a2, ...)
	if A < 0 then
		local l, t, r, b = arc_bound_core2(R, A + math.pi, a, a2, ...);
		return -r, -b, -l, -t;
	elseif A > math.pi / 2 then
		local l, t, r, b = arc_bound_core2(R, A - math.pi / 2, a, a2, ...);
		return -b, l, -t, r;
	elseif a2 then
		local l, t, r, b = arc_bound_core2(R, A, a);
		return union_rect(l, t, r, b, arc_bound_core2(R, A, a2, ...));
	elseif a < 0 then
		local l, t, r, b = arc_bound_core2(R, math.pi / 2 - A, -a)
		return t, l, b, r;
	end

	a = a + A;
	local l, t, r, b = -R, -R, R, R;
	if a < 0.5 * math.pi then b = R * math.sin(a) end
	if a < 1.0 * math.pi then l = R * math.cos(a) end
	if a < 1.5 * math.pi then t = R * math.sin(a) end
	if a < 2.0 * math.pi then r = R * math.cos(a) end
	return l, t, r, b;
end
local function arc_bound_core(x, y, ...)
	return arc_bound_core2((x ^ 2 + y ^ 2) ^ 0.5, math.atan2(y, x), ...);
end
local function arc_bound(left, top, right, bottom, ...)
	local l, t, r, b = arc_bound_core(left, top, ...);
	l, t, r, b = union_rect(l, t, r, b, arc_bound_core(right, top, ...));
	l, t, r, b = union_rect(l, t, r, b, arc_bound_core(right, bottom, ...));
	return union_rect(l, t, r, b, arc_bound_core(left, bottom, ...));
end

---拡大率・回転角・座標位置の移動元・移動先を指定し，
---その変化に沿ったブラーを適用する場合での，必要な画像拡大幅を計算する．
---この関数では実際には領域拡張は行わないし，最大画像サイズは考慮しない．
---`RadRotDirBlur_S()` 内で `keep_size` が `false` の場合に利用される．
---@param width integer 現在の画像の横幅，ピクセル単位．
---@param height integer 現在の画像の縦の高さ，ピクセル単位．
---@param scale1 number 移動元の拡大率，正数で指定，等倍は `1.0`.
---@param rotate1 number 移動元の回転角，ラジアン単位，時計回りに正．
---@param move_x1 number 移動元の X 座標の移動量，ピクセル単位，正で右方向．
---@param move_y1 number 移動元の Y 座標の移動量，ピクセル単位，正で右方向．
---@param scale2 number 移動先の拡大率，正数で指定，等倍は `1.0`.
---@param rotate2 number 移動先の回転角，ラジアン単位，時計回りに正．
---@param move_x2 number 移動先の X 座標の移動量，ピクセル単位，正で右方向．
---@param move_y2 number 移動先の Y 座標の移動量，ピクセル単位，正で右方向．
---@param center_x number 拡大や回転の中心の X 座標，ピクセル単位，画像の中央が原点，右に正．
---@param center_y number 拡大や回転の中心の Y 座標，ピクセル単位，画像の中央が原点，下に正．
---@return integer left 左方向の必要拡大量，0 以上の整数でピクセル単位．
---@return integer top 上方向の必要拡大量，0 以上の整数でピクセル単位．
---@return integer right 右方向の必要拡大量，0 以上の整数でピクセル単位．
---@return integer bottom 下方向の必要拡大量，0 以上の整数でピクセル単位．
local function calc_extra_size(width, height, scale1, rotate1, move_x1, move_y1, scale2, rotate2, move_x2, move_y2, center_x, center_y)
	-- find the final bounding box.
	local l, t, r, b =
		-width / 2 - center_x, -height / 2 - center_y,
		width / 2 - center_x, height / 2 - center_y;

	-- possible inflation by rotation.
	l, t, r, b = union_rect(l, t, r, b,
		arc_bound(l, t, r, b, rotate1, rotate2));

	-- possible inflation by scaling.
	local s = math.max(scale1, scale2);
	l, t, r, b = union_rect(l, t, r, b, s * l, s * t, s * r, s * b);

	-- possible inflation by movement.
	l = l + math.min(move_x1, move_x2);
	t = t + math.min(move_y1, move_y2);
	r = r + math.max(move_x1, move_x2);
	b = b + math.max(move_y1, move_y2);

	-- calculate and return the extra size required.
	return
		math.ceil(math.max(0, -l - center_x - width / 2)),
		math.ceil(math.max(0, -t - center_y - height / 2)),
		math.ceil(math.max(0, r + center_x - width / 2)),
		math.ceil(math.max(0, b + center_y - height / 2));
end

---拡大率・回転角・座標位置の移動元・移動先を指定し，その変化に沿ったブラーを適用する．
---`RadRotDirBlur_S()` の中核関数で，引数の範囲チェックや画像サイズの領域拡張などは行わない．
---@param scale1 number 移動元の拡大率，正数で指定，等倍は `1.0`.
---@param rotate1 number 移動元の回転角，ラジアン単位，時計回りに正．
---@param move_x1 number 移動元の X 座標の移動量，ピクセル単位，正で右方向．
---@param move_y1 number 移動元の Y 座標の移動量，ピクセル単位，正で右方向．
---@param scale2 number 移動先の拡大率，正数で指定，等倍は `1.0`.
---@param rotate2 number 移動先の回転角，ラジアン単位，時計回りに正．
---@param move_x2 number 移動先の X 座標の移動量，ピクセル単位，正で右方向．
---@param move_y2 number 移動先の Y 座標の移動量，ピクセル単位，正で右方向．
---@param center_x number 拡大や回転の中心の X 座標，ピクセル単位，画像の中央が原点，右に正．
---@param center_y number 拡大や回転の中心の Y 座標，ピクセル単位，画像の中央が原点，下に正．
---@param quality integer 1 ピクセルを計算するのに利用されるピクセル数．最小は `2`.
---@param reload boolean? GLShaderKit に対してシェーダーファイルの再読み込みを促す．デバッグ用．省略時は `false` と同等．
local function rad_rot_dir_blur(scale1, rotate1, move_x1, move_y1, scale2, rotate2, move_x2, move_y2, center_x, center_y, quality, reload)
	-- prepare shader context.
	GLShaderKit.activate()
	GLShaderKit.setPlaneVertex(1);
	GLShaderKit.setShader(shader_path, reload);

	-- send image buffer to gpu.
	local data, w, h = obj.getpixeldata();
	GLShaderKit.setTexture2D(0, data, w, h);

	-- send uniform variables.
	local scale, rotate, move_x, move_y, count =
		scale2 / scale1, rotate2 - rotate1,
		move_x2 - move_x1, move_y2 - move_y1, quality - 1;
	local c, s = scale ^ (-1 / count) * math.cos(-rotate / count), scale ^ (-1 / count) * math.sin(-rotate / count);
	local ini_c, ini_s = math.cos(-rotate1) / scale1, math.sin(-rotate1) / scale1;

	GLShaderKit.setMatrix("scale_rot", "2x2", false, { c, s * w / h, -s * h / w, c });
	GLShaderKit.setFloat("move", -move_x / count / w, -move_y / count / h);
	GLShaderKit.setMatrix("ini_scale_rot", "2x2", false, { ini_c, ini_s * w / h, -ini_s * h / w, ini_c });
	GLShaderKit.setFloat("ini_move", -move_x1 / w, -move_y1 / h);
	GLShaderKit.setFloat("center", center_x / w + 0.5, center_y / h + 0.5);
	GLShaderKit.setInt("count", count);

	-- invoke the shader.
	GLShaderKit.draw("TRIANGLES", data, w, h);

	-- close the shader context.
	GLShaderKit.deactivate();

	-- put back the result.
	obj.putpixeldata(data);
end

---放射・回転・方向の複合ブラーを適用．必要なら画像サイズを領域拡張する．
---@param radial_rate number 拡大率，正数で指定，等倍は `1.0`. 放射ブラーに対応する部分．
---@param rotate_rad number 回転角，ラジアン単位，時計回りに正．回転ブラーに対応する部分．
---@param direction_x number X 座標の移動量，ピクセル単位，正で右方向．方向ブラーに対応する部分．
---@param direction_y number Y 座標の移動量，ピクセル単位，正で下方向．方向ブラーに対応する部分．
---@param center_x number 拡大や回転の中心の X 座標，ピクセル単位，画像の中央が原点，右に正．
---@param center_y number 拡大や回転の中心の Y 座標，ピクセル単位，画像の中央が原点，下に正．
---@param relative_pos number ぼかし処理の基準位置，`0` で両端から伸びるように，`1.0` や `-1.0` で片側から伸びるようにぼかしがかかる．範囲は `-1.0` から `1.0`.
---@param quality integer 1 ピクセルを計算するのに利用されるピクセル数．最小は `2`.
---@param keep_size boolean サイズ固定をするかどうかを指定．固定しない場合，基本的には最低でも上下左右 1 ピクセルずつ拡大する．
---@param reload boolean? GLShaderKit に対してシェーダーファイルの再読み込みを促す．デバッグ用．省略時は `false` と同等．
local function RadRotDirBlur_S(radial_rate, rotate_rad, direction_x, direction_y, center_x, center_y, relative_pos, quality, keep_size, reload)
	-- adjust erroneous cases.
	if radial_rate <= 0 then radial_rate = 1 end
	quality = math.max(quality, 2);

	-- ignore trivial cases.
	if radial_rate == 1 and rotate_rad == 0 and direction_x == 0 and direction_y == 0 then return end

	-- calculate the beggining and ending states.
	local rel_pos1, rel_pos2 = (relative_pos - 1) / 2, (relative_pos + 1) / 2;
	local scale1, scale2 = radial_rate ^ rel_pos1, radial_rate ^ rel_pos2;
	local rotate1, rotate2 = rotate_rad * rel_pos1, rotate_rad * rel_pos2;
	local move_x1, move_x2 = direction_x * rel_pos1, direction_x * rel_pos2;
	local move_y1, move_y2 = direction_y * rel_pos1, direction_y * rel_pos2;

	-- expand the canvas unless specified.
	if not keep_size then
		local w, h = obj.getpixel();
		local l, t, r, b = calc_extra_size(w, h,
			scale1, rotate1, move_x1, move_y1,
			scale2, rotate2, move_x2, move_y2, center_x, center_y);
		l, t, r, b = math.max(1, l), math.max(1, t), math.max(1, r), math.max(1, b);

		-- cap to the maximum size of images.
		local max_w, max_h = obj.getinfo("image_max");
		if l + r + w > max_w then
			local diff = (l + r + w - max_w) / 2;
			l, r = l - math.ceil(diff), r - math.floor(diff);
			if l < 0 then l, r = 0, r + l end
			if r < 0 then l, r = l + r, 0 end
		end
		if t + b + h > max_h then
			local diff = (t + b + h - max_h) / 2;
			t, b = t - math.ceil(diff), b - math.floor(diff);
			if t < 0 then t, b = 0, b + t end
			if b < 0 then t, b = t + b, 0 end
		end

		-- expand the canvas and reposition the center.
		obj.effect("領域拡張", "上", t, "下", b, "左", l, "右", r);
		center_x, center_y = center_x + (l - r) / 2, center_y + (t - b) / 2;
	end

	-- apply the blur.
	rad_rot_dir_blur(
		scale1, rotate1, move_x1, move_y1,
		scale2, rotate2, move_x2, move_y2,
		center_x, center_y, quality, reload);
end

-- register a table.
return {
	RadRotDirBlur_S = RadRotDirBlur_S,
	rad_rot_dir_blur = rad_rot_dir_blur,
	calc_extra_size = calc_extra_size,
};
