shader_type canvas_item;
render_mode unshaded;
uniform float iris_size: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float feather: hint_range(0.0, 0.2, 0.01) = 0.05;
uniform float overlay_opacity: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform vec2 centre = vec2(0.5, 0.5);
void fragment() {
    COLOR.rgb = vec3(0.0);
    vec2 ratio = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
    float max_dist = length(vec2(max(centre.x, 1.0 - centre.x), max(centre.y, 1.0 - centre.y)) * ratio);
    float radius = mix(-feather, max_dist, iris_size);
    float dist = length(ratio * (SCREEN_UV - centre));
    float mask = smoothstep(radius, radius + feather, dist);
    COLOR.a = mask * overlay_opacity;
}