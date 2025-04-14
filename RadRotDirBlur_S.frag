/*
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
*/

//
// VERSION: v1.10
//

////////////////////////////////
#version 460 core

in vec2 TexCoord;

layout(location = 0) out vec4 FragColor;

uniform sampler2D texture0;
uniform mat2 scale_rot;
uniform vec2 move;
uniform mat2 ini_scale_rot;
uniform vec2 ini_move;
uniform vec2 center;
uniform int count;

void main()
{
	vec2 v = ini_scale_rot * (TexCoord - center + ini_move), d = ini_scale_rot * move;

	vec4 color = texture(texture0, v + center);
	color.rgb *= color.a;
	for (int i = 0; i < count; i++) {
		v = scale_rot * (v + d); d = scale_rot * d;

		vec4 c = texture(texture0, v + center);
		c.rgb *= c.a;
		color += c;
	}

	if (color.a > 0) {
		color.rgb /= color.a;
		color.a /= count + 1;
	}

    FragColor = color;
}
