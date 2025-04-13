
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
-- VERSION: v1.00
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
local function arc_bound_core(x, y, a, a2, ...)
	if a2 then
		local l, t, r, b = arc_bound_core(x, y, a);
		return union_rect(l, t, r, b, arc_bound_core(x, y, a2, ...));
	elseif x < 0 then
		local l, t, r, b = arc_bound_core(-x, y, -a);
		return -r, t, -l, b;
	elseif y < 0 then
		local l, t, r, b = arc_bound_core(x, -y, -a);
		return l, -b, r, -t;
	elseif a < 0 then
		local t, l, b, r = arc_bound_core(y, x, -a)
		return l, t, r, b;
	end
	local A, R = a + math.atan(y / x), (x ^ 2 + y ^ 2) ^ 0.5;
	local l, t, r, b = -R, -R, R, R;
	if A < 0.5 * math.pi then b = R * math.sin(A) end
	if A < 1.0 * math.pi then l = R * math.cos(A) end
	if A < 1.5 * math.pi then t = R * math.sin(A) end
	if A < 2.0 * math.pi then r = R * math.cos(A) end
	return l, t, r, b;
end
local function arc_bound(left, top, right, bottom, ...)
	local l, t, r, b = union_rect(
		left, top, right, bottom, arc_bound_core(left, top, ...));
	l, t, r, b = union_rect(l, t, r, b, arc_bound_core(right, top, ...));
	l, t, r, b = union_rect(l, t, r, b, arc_bound_core(right, bottom, ...));
	return union_rect(l, t, r, b, arc_bound_core(left, bottom, ...));
end

---放射・回転・方向の複合ブラーを適用．
---@param radial_rate number 拡大率，等倍は `1.0`. 放射ブラーに対応する部分．
---@param rotate_rad number 回転角，ラジアン単位．回転ブラーに対応する部分．
---@param direction_x number X 座標の移動量，ピクセル単位．方向ブラーに対応する部分．
---@param direction_y number Y 座標の移動量，ピクセル単位．方向ブラーに対応する部分．
---@param center_x number 拡大や回転の中心の X 座標，ピクセル単位，画像の中央が原点．
---@param center_y number 拡大や回転の中心の Y 座標，ピクセル単位，画像の中央が原点．
---@param relative_pos number ぼかし処理の基準位置，`0` で両端から伸びるように，`1.0` や `-1.0` で片側から伸びるようにぼかしがかかる．範囲は `-1.0` から `1.0`.
---@param quality integer 1ピクセルを計算するのに利用されるピクセル数．最小は `2`.
---@param keep_size boolean サイズ固定をするかどうかを指定．
---@param reload boolean? GLShaderKit に対してシェーダーファイルの再読み込みを促す．デバッグ用．
local function RadRotDirBlur_S(radial_rate, rotate_rad, direction_x, direction_y, center_x, center_y, relative_pos, quality, keep_size, reload)
	-- ignore trivial cases.
	if radial_rate == 1 and rotate_rad == 0 and direction_x == 0 and direction_y == 0 then return end

	local rel_st, rel_ed = (relative_pos - 1) / 2, (relative_pos + 1) / 2;

	-- expand the canvas unless specified.
	if not keep_size then
		-- find the final bounding box.
		local w, h = obj.getpixel();
		local l, t, r, b = -w / 2 - center_x, -h / 2 - center_y, w / 2 - center_x, h / 2 - center_y;

		-- possible inflation by rotation.
		l, t, r, b = arc_bound(l, t, r, b, rel_st * rotate_rad, rel_ed * rotate_rad);

		-- possible inflation by scaling.
		local s = math.max(radial_rate ^ rel_st, radial_rate ^ rel_ed);
		l, t, r, b = union_rect(l, t, r, b, s * l, s * t, s * r, s * b);

		-- possible inflation by movement.
		l = l + math.min(rel_st * direction_x, rel_ed * direction_x);
		t = t + math.min(rel_st * direction_y, rel_ed * direction_y);
		r = r + math.max(rel_st * direction_x, rel_ed * direction_x);
		b = b + math.max(rel_st * direction_y, rel_ed * direction_y);

		-- reposition the center and expand the canvas.
		l, t, r, b = l + center_x, t + center_y, r + center_x, b + center_y;
		l, t, r, b = math.max(0, -l - w / 2), math.max(0, -t - h / 2), math.max(0, r - w / 2), math.max(0, b - h / 2);
		obj.effect("領域拡張", "上", t, "下", b, "左", l, "右", r);
		center_x, center_y = center_x + (l - r) / 2, center_y + (t - b) / 2;
	end

	-- prepare shader context.
	GLShaderKit.activate()
	GLShaderKit.setPlaneVertex(1);
	GLShaderKit.setShader(shader_path, reload);

	-- send image buffer to gpu.
	local data, w, h = obj.getpixeldata();
	GLShaderKit.setTexture2D(0, data, w, h);

	-- send uniform variables.
	local count, ini_pos = math.max(quality, 2) - 1, (relative_pos - 1) / 2;
	local c, s = radial_rate ^ (-1 / count) * math.cos(-rotate_rad / count), radial_rate ^ (-1 / count) * math.sin(-rotate_rad / count);
	local ini_c, ini_s = radial_rate ^ -ini_pos * math.cos(-rotate_rad * ini_pos), radial_rate ^ -ini_pos * math.sin(-rotate_rad * ini_pos);

	GLShaderKit.setMatrix("scale_rot", "2x2", false, { c, s * w / h, -s * h / w, c });
	GLShaderKit.setFloat("move", -direction_x / count / w, -direction_y / count / h);
	GLShaderKit.setMatrix("ini_scale_rot", "2x2", false, { ini_c, ini_s * w / h, -ini_s * h / w, ini_c });
	GLShaderKit.setFloat("ini_move", -direction_x * ini_pos / w, -direction_y * ini_pos / h);
	GLShaderKit.setFloat("center", center_x / w + 0.5, center_y / h + 0.5);
	GLShaderKit.setInt("count", count);

	-- invoke the shader.
	GLShaderKit.draw("TRIANGLES", data, w, h);

	-- close the shader context.
	GLShaderKit.deactivate();

	-- put back the result.
	obj.putpixeldata(data);
end

-- register a table.
return {
	RadRotDirBlur_S = RadRotDirBlur_S,
};
