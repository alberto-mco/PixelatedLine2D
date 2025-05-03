@tool

extends EditorPlugin

#Enumeraciones
enum MODES { VIEW, ADD, EDIT, DELETE }

#Variables privadas
var _selected_node:Node					= null
var _hbox:HBoxContainer					= null
var _btn_add_mode:Button				= null
var _btn_edit_mode:Button				= null
var _btn_remove_mode:Button				= null
var _mode:MODES							= MODES.VIEW
var _point_idx:int						= -1
var _button_idx:int						= -1

#=======================================================================
#Enter tree
#=======================================================================
func _enter_tree()->void:
	#Inicializamos las instancias
	_hbox = HBoxContainer.new()
	_btn_add_mode = Button.new()
	_btn_edit_mode = Button.new()
	_btn_remove_mode = Button.new()
	
	#Inicializamos los botones
	_btn_add_mode.text = "Add"
	_btn_add_mode.toggle_mode = true
	
	_btn_edit_mode.text = "Edit"
	_btn_edit_mode.toggle_mode = true
	
	_btn_remove_mode.text = "Remove"
	_btn_remove_mode.toggle_mode = true
	
	#Conectamos las señales que emiten los botones
	_btn_add_mode.pressed.connect(_on_add_mode)
	_btn_edit_mode.pressed.connect(_on_edit_mode)
	_btn_remove_mode.pressed.connect(_on_remove_mode)
	
	#Insertamos los botones en el contenedor
	_hbox.add_child(_btn_add_mode)
	_hbox.add_child(_btn_edit_mode)
	_hbox.add_child(_btn_remove_mode)
	
	#Añadimos el contenedor a la barra del editor
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, _hbox)
	
	#Ocultamos inicialmente el contenedor
	_hbox.visible = false
	
	#Registramos el tipo personalizado
	add_custom_type("PixelatedLine2D", "Node2D", preload("res://addons/pixelatedline2d/pixelatedline2d.gd"), null)
	
	#Refresca el modo
	_refresh_current_mode()

#=======================================================================
#Exit tree
#=======================================================================
func _exit_tree()->void:
	#Eliminamos el contenedor y todos los controles que contiene
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, _hbox)
	
	#Quitamos el registro del tipo personalizado
	remove_custom_type("PixelatedLine2D")

#=======================================================================
#Input
#=======================================================================
func _forward_canvas_gui_input(p_event:InputEvent)->bool:
	var l_result:bool = false
	
	#Comprobamos el tipo de event
	if (p_event is InputEventMouseButton):
		var l_event:InputEventMouseButton = p_event
		
		#Comprobamos si el botón del ratón está presionado
		if (l_event.pressed):
			#Comprobamos si es un botón del ratón con el que permitimos la interacción, y además no hay ningún botón más presionado
			if ((l_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]) and (_button_idx == -1)):
				var l_selected_nodes:Array[Node] = EditorInterface.get_selection().get_selected_nodes()
				
				#Comprobamos si hay algún nodo válido
				if ((l_selected_nodes.size() > 0) and (l_selected_nodes.front() is PixelatedLine2D)):
					var l_node:PixelatedLine2D = l_selected_nodes.front()
					var l_mode:MODES = _mode if (l_event.button_index != MOUSE_BUTTON_RIGHT) else MODES.DELETE
					var l_local_pos:Vector2 = l_node.to_local(_get_viewport_mouse_position())
					
					#Comprobamos el tipo de modo
					match (l_mode):
						MODES.ADD:
							#Insertamos el nuevo punto
							l_node.add_point(l_local_pos)
						MODES.EDIT:
							#Buscamos el punto seleccionado
							_point_idx = l_node.search_point_index(l_local_pos)
						MODES.DELETE:
							#Eliminamos el punto actual que pueda haber en la coordenada indicada
							l_node.remove_point_at(l_local_pos)
					
					#Guardamos el índice del botón que se ha presionado
					_button_idx = l_event.button_index
					
					#Marcamos el flag para indicar que hemos controlado del evento de input, y así evitar que se siga propagando el evento
					l_result = true
		else:
			#Comprobamos si se ha liberado la presión del botón que estaba realizando alguna acción
			if (_button_idx == l_event.button_index):
				#Olvidamos el punto en el que se había hecho clic (en caso de que hubiese alguno)
				_point_idx = -1
				
				#Olvidamos el índice del botón presionado
				_button_idx = -1
	elif ((p_event is InputEventMouseMotion) and (_mode == MODES.EDIT)):
		var l_event:InputEventMouseMotion = p_event
		
		#Comprobamos si está presionado y hay algún punto seleccionado
		if (l_event.pressure > 0.0) and (_point_idx > -1):
			var l_selected_nodes:Array[Node] = EditorInterface.get_selection().get_selected_nodes()
			
			#Comprobamos si hay algún nodo válido
			if ((l_selected_nodes.size() > 0) and (l_selected_nodes.front() is PixelatedLine2D)):
				var l_node:PixelatedLine2D = l_selected_nodes.front()
				var l_local_pos:Vector2 = l_node.to_local(_get_viewport_mouse_position())
				
				#Movemos el punto
				l_node.set_point_position(_point_idx, l_local_pos)
				
				#Marcamos el flag para indicar que hemos controlado del evento de input, y así evitar que se siga propagando el evento
				l_result = true
	
	return l_result

#=======================================================================
#Comprueba si es el tipo de objeto que administra este plugin
#=======================================================================
func _handles(p_object:Object)->bool:
	return p_object is PixelatedLine2D

#=======================================================================
#Obtiene el objeto seleccionado en el editor, y actuamos en consecuencia
#=======================================================================
func _edit(p_object:Object)->void:
	#Comprobamos el tipo de objeto seleccionado
	if (p_object is PixelatedLine2D):
		#Guardamos la referencia al nodo seleccionado
		_selected_node = p_object
		
		#Mostramos el contenedor con los controles para editar el nodo
		_hbox.visible = true
	else:
		#Quitamos la referencia al nodo seleccionado
		_selected_node = null
		
		#Ocultamos el contenedor con los controles para editar el nodo
		_hbox.visible = false

#=======================================================================
#Función que será llamada cuando se solicite que el editor se haga visible.
#=======================================================================
func _make_visible(p_visible:bool):
	#Mostramos u ocultamos el contenedor con los controles de edición
	_hbox.visible = p_visible
	
	#Comprobamos si los controles de edición están ocultos
	if (p_visible == false):
		#Quitamos la referencia al nodo seleccionado
		_selected_node = null

#=======================================================================
#Libera la presión en todos los botones, nenos en el que se indica en el parámetro
#=======================================================================
func _release_other_buttons(p_skip_button:Button)->void:
	#Recorremos todos los botones que tiene el hbox
	for l_child_button:Button in _hbox.get_children():
		#Comprobamos que no sea el botón que tiene que mantener el estado actual de presionado
		if (l_child_button != p_skip_button):
			#Liberamos la presión en el botón
			l_child_button.button_pressed = false

#=======================================================================
#Refresca el modo en el que se encuentra el editor
#=======================================================================
func _refresh_current_mode()->void:
	var l_new_mode:MODES = MODES.VIEW
	
	#Comprobamos que botón está presionado
	if (_btn_add_mode.button_pressed):
		l_new_mode = MODES.ADD
	elif (_btn_edit_mode.button_pressed):
		l_new_mode = MODES.EDIT
	elif (_btn_remove_mode.button_pressed):
		l_new_mode = MODES.DELETE
	
	#Guardamos el nuevo modo
	_mode = l_new_mode

#=======================================================================
#Obtiene la posición del mouse dentro del viewport
#=======================================================================
func _get_viewport_mouse_position()->Vector2:
	var l_editor_viewport:SubViewport = EditorInterface.get_editor_viewport_2d()
	var l_mouse_position:Vector2 = l_editor_viewport.get_mouse_position()
	
	#No permitimos decimales
	l_mouse_position.x = roundf(l_mouse_position.x)
	l_mouse_position.y = roundf(l_mouse_position.y)
	
	return l_mouse_position

#=======================================================================
#Función para capturar la señal del botón para establecer el modo de añadir puntos
#=======================================================================
func _on_add_mode():
	#Comprobamos si hay algún nodo seleccionado
	if (_selected_node != null):
		#Comprobamos si el botón está presionado
		if (_btn_add_mode.button_pressed):
			#Liberamos la presión en los otros botones
			_release_other_buttons(_btn_add_mode)
		
		#Refrescamos el modo actual
		_refresh_current_mode()

#=======================================================================
#Función para capturar la señal del botón para establecer el modo de editar puntos
#=======================================================================
func _on_edit_mode()->void:
	#Comprobamos si hay algún nodo seleccionado
	if (_selected_node != null):
		#Comprobamos si el botón está presionado
		if (_btn_edit_mode.button_pressed):
			#Liberamos la presión en los otros botones
			_release_other_buttons(_btn_edit_mode)
		
		#Refrescamos el modo actual
		_refresh_current_mode()

#=======================================================================
#Función para capturar la señal del botón para establecer el modo de eliminar puntos
#=======================================================================
func _on_remove_mode():
	#Comprobamos si hay algún nodo seleccionado
	if (_selected_node != null):
		#Comprobamos si el botón está presionado
		if (_btn_remove_mode.button_pressed):
			#Liberamos la presión en los otros botones
			_release_other_buttons(_btn_remove_mode)
		
		#Refrescamos el modo actual
		_refresh_current_mode()
