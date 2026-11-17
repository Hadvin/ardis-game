shader_type spatial;

// Настройки трипланарного проецирования
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Масштабирует яркость всей текстуры
uniform vec4 background_color : source_color = vec4(0.7, 0.4, 0.1, 1.0); // Новый цвет вместо черного (по умолчанию оранжевый)
uniform sampler2D texture_grid : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 texture_scale = vec3(0.25); // Масштаб сетки (0.25 отлично подходит для текстур 512x512)
uniform float sharpness : hint_range(1.0, 64.0) = 8.0; // Четкость переходов на стыках граней

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Получаем корректные мировые нормали с учетом масштаба объекта
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Расчет весов смешивания для трех плоскостей (X, Y, Z)
	vec3 blend_weights = pow(abs(world_normal), vec3(sharpness));
	blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);
	
	// Масштабируем мировые координаты для правильного наложения сетки
	vec3 uv_scaled = world_position * texture_scale;
	
	// Выборка текстуры с трех сторон (Трипланарное картирование)
	vec4 tex_x = texture(texture_grid, uv_scaled.zy);
	vec4 tex_y = texture(texture_grid, uv_scaled.xz);
	vec4 tex_z = texture(texture_grid, uv_scaled.xy);
	
	// Смешиваем текстуру согласно ориентации нормалей поверхностей
	vec4 mixed_texture = tex_x * blend_weights.x + tex_y * blend_weights.y + tex_z * blend_weights.z;
	
	// Смешиваем фоновый цвет с белыми/серыми линиями на основе яркости текстуры
	// Чем белее пиксель сетки, тем ближе финальный цвет к белому
	vec3 final_color = mix(background_color.rgb, vec3(1.0), mixed_texture.rgb);
	
	// Финальный цвет: применяем albedo_color для общих корректировок
	ALBEDO = final_color * albedo_color.rgb;
	ROUGHNESS = 0.6;
	SPECULAR = 0.1;
}