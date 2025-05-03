@tool

extends Node2D

class_name PixelatedLine2D

#Variables públicas exportadas
@export var points:PackedVector2Array								= [] : set = _set_points, get = _get_points
@export var color:Color												= Color.WHITE : set = _set_color, get = _get_color
@export var closed:bool												= false : set = _set_closed, get = _get_closed
@export_range(1.0, 100.0, 1.0) var width:float						= 1.0 : set = _set_width, get = _get_width
@export_range(1.0, 100.0, 0.1) var selection_point_radius:float		= 5.0 : set = _set_selection_point_radius, get = _get_selection_point_radius
@export var selection_point_border_color:Color						= Color.BLACK : set = _set_selection_point_border_color, get = _get_selection_point_border_color
@export var selection_point_fill_color:Color						= Color.WHITE : set = _set_selection_point_fill_color, get = _get_selection_point_fill_color
@export var antialiased:bool										= false : set = _set_antialiased, get = _get_antialiased

##Draw
func _draw()->void:
	#Comprobamos si el script se está ejecutando desde el editor
	if Engine.is_editor_hint():
		#Recorremos todos los puntos
		for l_point:Vector2 in points:
			draw_circle(l_point, selection_point_radius, selection_point_border_color, true, -1.0, antialiased)
			draw_circle(l_point, selection_point_radius * 0.75, selection_point_fill_color, true, -1.0, antialiased)
	
	#Comprobamos que al menos haya 2 puntos
	if (points.size() >= 2):
		#Recorremos todos los puntos
		for i in range(points.size() - 1):
			#Dibujamos la línea pixelada
			_draw_pixelated_line(points[i], points[i + 1], color, width)
		
		#Comprobamos si hay al menos 3 puntos
		if ((points.size() > 2) and (closed)):
			#Dibujamos la línea pixelada
			_draw_pixelated_line(points[0], points[points.size() - 1], color, width)

##Propiedad "Points"
func _set_points(p_value:PackedVector2Array)->void:
	#Vaciamos la lista de puntos actuales
	points.clear()
	
	#Guardamos los nuevos puntos
	points.append_array(p_value)
	
	#Redibujamos la línea
	queue_redraw()
func _get_points()->PackedVector2Array:
	return points

##Propiedad "Color"
func _set_color(p_color:Color)->void:
	#Guardamos el nuevo color seleccionado
	color = p_color
	
	#Redibujamos la línea
	queue_redraw()
func _get_color()->Color:
	return color

##Propiedad "Closed"
func _set_closed(p_value:bool)->void:
	#Guardamos el nuevo valor
	closed = p_value
	
	#Redibujamos la línea
	queue_redraw()
func _get_closed()->bool:
	return closed

##Propiedad "Width"
func _set_width(p_value:float)->void:
	#Guardamos el nuevo valor
	width = p_value
	
	#Redibujamos la línea
	queue_redraw()
func _get_width()->float:
	return width

##Propiedad "Selection point radius"
func _set_selection_point_radius(p_value:float)->void:
	#Guardamos el nuevo valor
	selection_point_radius = p_value
	
	#Redibujamos la línea
	queue_redraw()
func _get_selection_point_radius()->float:
	return selection_point_radius

##Propiedad "Selection point border color"
func _set_selection_point_border_color(p_color:Color)->void:
	#Guardamos el nuevo color seleccionado
	selection_point_border_color = p_color
	
	#Redibujamos la línea
	queue_redraw()
func _get_selection_point_border_color()->Color:
	return selection_point_border_color

##Propiedad "Selection point fill color"
func _set_selection_point_fill_color(p_color:Color)->void:
	#Guardamos el nuevo color seleccionado
	selection_point_fill_color = p_color
	
	#Redibujamos la línea
	queue_redraw()
func _get_selection_point_fill_color()->Color:
	return selection_point_fill_color

##Propiedad "Antialiased"
func _set_antialiased(p_enabled:bool)->void:
	#Guardamos el nuevo valor
	antialiased = p_enabled
	
	#Redibujamos la línea
	queue_redraw()
func _get_antialiased()->bool:
	return antialiased

##Dibuja una línea pixelada
func _draw_pixelated_line(p_source:Vector2, p_target:Vector2, p_color:Color, p_width:float)->void:
	var l_segments:PackedVector2Array = _get_segments(p_source, p_target, p_width)
	
	#Comprobamos que haya un total de segmentos válidos
	if ((l_segments.size() > 0) and (l_segments.size() % 2 == 0)):
		#Dibujamos la línea
		draw_multiline(l_segments, p_color, p_width, antialiased)

##Obtiene los segmentos que hay entre un punto y otro punto
func _get_segments(p_source:Vector2, p_target:Vector2, p_width:float)->PackedVector2Array:
	var l_segments:PackedVector2Array
	var l_direction:Vector2 = (p_target - p_source)
	var l_ndirection:Vector2 = l_direction.normalized()
	var l_segments_count:int = 0
	
	#Comprobamos la dirección en la que van los segmentos
	if (absf(l_ndirection.x) > absf(l_ndirection.y)): #Lineas horizontales
		#Calculamos el total de segmentos
		l_segments_count = ceili(absf(l_direction.y / p_width))
		
		#Comprobamos si es una línea recta
		if (l_segments_count == 0):
			#Guardamos el inicio del segmento
			l_segments.append(p_source)
			l_segments.append(p_target)
		else:
			#Insertamos el segmento final
			l_segments_count += 1
			
			var l_segment_increment:Vector2 = Vector2(l_direction.x / l_segments_count, p_width if (l_direction.y / l_segments_count) > 0 else -p_width)
			var l_segment_start:Vector2 = p_source
			
			#Recorremos todos los segmentos
			for l_i:int in range(l_segments_count):
				#Guardamos el inicio del segmento
				l_segments.append(l_segment_start)
				l_segments.append(l_segment_start + Vector2(l_segment_increment.x, 0))
				
				#Establecemos el siguiente inicio de segmento
				l_segment_start = l_segment_start + l_segment_increment
	else: #Lineas verticales
		#Calculamos el total de segmentos
		l_segments_count = ceili(absf(l_direction.x / p_width))
		
		#Comprobamos si es una línea recta
		if (l_segments_count == 0):
			#Guardamos el inicio del segmento
			l_segments.append(p_source)
			l_segments.append(p_target)
		else:
			#Insertamos el segmento final
			l_segments_count += 1
			
			var l_segment_increment:Vector2 = Vector2(p_width if (l_direction.x / l_segments_count) > 0 else -p_width, l_direction.y / l_segments_count)
			var l_segment_start:Vector2 = p_source
			
			#Recorremos todos los segmentos
			for l_i:int in range(l_segments_count):
				#Guardamos el inicio del segmento
				l_segments.append(l_segment_start)
				l_segments.append(l_segment_start + Vector2(0, l_segment_increment.y))
				
				#Establecemos el siguiente inicio de segmento
				l_segment_start = l_segment_start + l_segment_increment
	
	return l_segments

##Comprueba si la posición está dentro del radio del círculo
func _is_within_radius(p_position:Vector2, p_circle_center_position:Vector2, p_circle_radius:float)->bool:
	var l_distance:float = (p_position - p_circle_center_position).length()
	return (l_distance <= p_circle_radius)

##Obtiene el punto más cercano a la posición indicada
func _get_nearest_point_index(p_position:Vector2)->int:
	var l_result:int = -1
	var l_result_length:float = -1
	
	#Recorremos todos los puntos
	for l_point_index:int in range(points.size()):
		var l_point:Vector2 = points[l_point_index]
		
		#Comprobamos si el punto está dentro del radio
		if (_is_within_radius(p_position, l_point, selection_point_radius)):
			#Comprobamos si no es el primer punto que coincide
			if (l_result > -1):
				#Comprobamos si el punto está más cerca que el anterior
				if ((p_position - l_point).length() < l_result_length):
					#Guardamos el índice del punto y la distancia hasta la posición
					l_result = l_point_index
					l_result_length = (p_position - l_point).length()
			else:
				#Guardamos el índice del punto y la distancia hasta la posición
				l_result = l_point_index
				l_result_length = (p_position - l_point).length()
	
	return l_result

##Inserta un punto en la línea
func add_point(p_position:Vector2, p_index:int = -1)->void:
	var l_added:bool = false
	var l_old_points = points.duplicate()
	var l_new_points = points.duplicate()
	
	#Comprobamos si debemos de insertar el punto en alguna posición concreta del array
	if ((p_index > -1) and (p_index <= l_old_points.size())):
		#Insertamos el punto
		l_new_points.insert(p_index, p_position)
		
		#Marcamos el flag para indicar que hemos añadido un nuevo punto
		l_added = true
	else:
		#Insertamos el punto
		l_new_points.append(p_position)
		
		#Marcamos el flag para indicar que hemos añadido un nuevo punto
		l_added = true
	
	#Comprobamos si se ha añadido algún nuevo punto
	if (l_added):
		#Comprobamos si el script se está ejecutando desde el editor
		if (Engine.is_editor_hint()):
			var l_scene_root = EditorInterface.get_edited_scene_root()
			var l_undo_redo = EditorInterface.get_editor_undo_redo()
			
			l_undo_redo.create_action("Add Point to PixelatedLine2D")
			l_undo_redo.add_do_property(self, "points", l_new_points)
			l_undo_redo.add_do_method(self, "notify_property_list_changed")
			l_undo_redo.add_undo_property(self, "points", l_old_points)
			l_undo_redo.add_undo_method(self, "notify_property_list_changed")
			l_undo_redo.commit_action()
		else:
			#Guardamos la nueva lista de puntos
			points = l_new_points

##Elimina todos los puntos
func clear_points()->void:
	#Comprobamos si hay puntos que eliminar
	if (points.size() > 0):
		var l_old_points = points.duplicate()
		var l_new_points = points.duplicate()
		
		#Eliminamos todos los puntos
		l_new_points.clear()
		
		#Comprobamos si el script se está ejecutando desde el editor
		if (Engine.is_editor_hint()):
			var l_scene_root = EditorInterface.get_edited_scene_root()
			var l_undo_redo = EditorInterface.get_editor_undo_redo()
			
			l_undo_redo.create_action("Remove Point to PixelatedLine2D")
			l_undo_redo.add_do_property(self, "points", l_new_points)
			l_undo_redo.add_do_method(self, "notify_property_list_changed")
			l_undo_redo.add_undo_property(self, "points", l_old_points)
			l_undo_redo.add_undo_method(self, "notify_property_list_changed")
			l_undo_redo.commit_action()
		else:
			#Guardamos la nueva lista de puntos
			points = l_new_points

##Obtiene el total de puntos que contiene la línea
func get_point_count()->int:
	return points.size()

##Obtiene la posición que hay en el índice indicado
func get_point_position(p_index:int)->Vector2:
	var l_pos:Vector2 = Vector2.ZERO
	
	#Comprobamos que sea un índice válido
	if ((p_index > -1) and (p_index < points.size())):
		#Obtenemos el punto
		l_pos = points[p_index]
	
	return l_pos

##Busca el índice del punto más cercano a la posición indicada
func search_point_index(p_position:Vector2)->int:
	return _get_nearest_point_index(p_position)

##Elimina un punto
func remove_point(p_index:int)->void:
	#Comprobamos que sea un índice válido
	if ((p_index > -1) and (p_index < points.size())):
		var l_old_points = points.duplicate()
		var l_new_points = points.duplicate()
		
		#Eliminamos el punto
		l_new_points.remove_at(p_index)
		
		#Comprobamos si solo queda 1 punto
		if (l_new_points.size() == 1):
			#Eliminamos el último punto
			l_new_points.clear()
		
		#Comprobamos si el script se está ejecutando desde el editor
		if (Engine.is_editor_hint()):
			var l_scene_root = EditorInterface.get_edited_scene_root()
			var l_undo_redo = EditorInterface.get_editor_undo_redo()
			
			l_undo_redo.create_action("Remove Point to PixelatedLine2D")
			l_undo_redo.add_do_property(self, "points", l_new_points)
			l_undo_redo.add_do_method(self, "notify_property_list_changed")
			l_undo_redo.add_undo_property(self, "points", l_old_points)
			l_undo_redo.add_undo_method(self, "notify_property_list_changed")
			l_undo_redo.commit_action()
		else:
			#Guardamos la nueva lista de puntos
			points = l_new_points

##Elimina el punto más cercano a la posición indicada
func remove_point_at(p_position:Vector2)->void:
	var l_point_index:int = _get_nearest_point_index(p_position)
	
	#Comprobamos si se ha encontrado algún punto
	if (l_point_index > -1):
		#Eliminamos el punto
		remove_point(l_point_index)

##Establece la posición del punto
func set_point_position(p_index:int, p_position:Vector2)->void:
	#Comprobamos que sea un índice válido
	if ((p_index > -1) and (p_index < points.size())):
		#Eliminamos el punto actual
		points.remove_at(p_index)
		
		#Insertamos el nuevo punto
		points.insert(p_index, p_position)
		
		#Redibujamos la línea
		queue_redraw()
		
		#Comprobamos si el script se está ejecutando desde el editor
		if (Engine.is_editor_hint()):
			#Notificamos al editor los cambios
			notify_property_list_changed()
