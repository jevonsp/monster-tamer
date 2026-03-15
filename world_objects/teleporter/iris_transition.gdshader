shader_type canvas_item;
render_mode unshaded;
// iris shader, apply to a ColorRect that overlays the screen and set iris_size to iris in and out

// 0.0 = fully close,  1.0 = fully open
uniform float iris_size:hint_range(0.0, 1.0, 0.01) = 0.5;

// how blurry the edge of the iris should be
uniform float feather:hint_range(0.0, 0.2, 0.01) = 0.05;

// centre point of the iris
uniform vec2 centre = vec2(0.5, 0.5);


void fragment() {
	COLOR.rgb = vec3(0.0); // black
	
	// ratio does assume we're on landscape screen, if you can't assume that this needs more
	vec2 ratio = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	// max distance from centre to corners
	float max_dist = length(vec2(max(centre.x, 1.0 - centre.x), max(centre.y, 1.0 - centre.y)) * ratio);
	float radius = mix(-feather, max_dist, iris_size);
	float dist = length(ratio * (SCREEN_UV - centre));
	COLOR.a = smoothstep(radius, radius + feather, dist);
}