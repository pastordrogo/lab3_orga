.data
	message: .asciiz "\nEstoy ejecutando sort...\n"
	fallo_arg: .asciiz "\nFaltan o sobran argumentos\n\t java -jar Mars4_4.jar busqueda_lineal.asm pa [ARCHIVO_ENTRADA] [ARCHIVO_SALIDA]\n"
	error_posicion_negativa_insertar_posicion: .asciiz "\nError en procedimiento insertar_posicion: Posicion otorgada fuera de rango, es negativa\n"
	error_posicion_mayor_insertar_posicion: .asciiz "\nError en procedimiento insertar_posicion: Posicion otorgada fuera de rango, es mayor al numero de datos\n"
	error_posicion_negativa_dato_en_posicion: .asciiz "\nError en procedimiento dato_en_posicion: Posicion otorgada fuera de rango, es negativa\n"
	error_posicion_mayor_dato_en_posicion: .asciiz "\nError en procedimiento dato_en_posicion: Posicion otorgada fuera de rango, es mayor al numero de datos\n"
	mensaje_error_character_to_int: .asciiz "\nEl caracter ASCII está fuera del rango de digitos decimales entre 0 y 9 (48~57)"
	buffer: .space 1048576
	salto_linea: .asciiz "\n"
	file: .asciiz "input/CP_0.txt"
	fout: .asciiz "salidaRec.txt"
.text
	main:
		#INT MAX : 2147483647
		#Lectura y carga de archivo en lista
		# $a0 tiene a argc y $a1 tiene a argv(lista de argumentos)
		# para acceder a primer elemento de argv lw $t0, 0($a1)

		#Se verifica que el número de argumentos es el correcto
		#bne $a0, 2, fallo_entrada_argumentos
		#lw $s5, 0($a1) #argv[0] entrada
		#addi $sp, $sp,-4
		#lw $s0,4($a1)
		#sw $s0,0($sp) #En el stack guardo la direcion al archivo
				#de salida para escribir luego
		#Entra al if
		###############################################################
  		# Open (for reading) a file that does not exist
  		li   $v0, 13       # system call for open file
  		#la   $a0, ($s5)     # input file name
  		la $a0, file
  		li   $a1, 0        # Open for reading (flags are 0: read, 1: write)
  		li   $a2, 0        # mode is ignored
  		syscall            # open a file (file descriptor returned in $v0)
		move $s0, $v0      # save the file descriptor
		###############################################################
			# Read to file just opened
			li   $v0, 14       # system call for read to file
			move $a0, $s0      # file descriptor
			la   $a1, buffer   # address of buffer in which to read
			li   $a2, 1048576    # hardcoded buffer length
			syscall            # read to file
			move $s2, $v0
			addi $s2, $s2,-2
			la $s1, buffer	 #$s1 = direccion de buffer, todas las lineas del archivo
			addi $s6,$zero,0
			addi $s5,$zero,0
			add $s4, $zero,$zero #puntero a cabeza de la lista L=NULL
			add $s3,$zero,0
			li $k1,0
			loop_lectura:
				#beq  $s3,45,numero_negativo # pregunta si existe un signo menos o negativo
				ble $s2,-1, end_loop_lectura
				add $t9, $s2,$s1 # obtencion de direccion de caracter
				lb $s3,($t9) #obtencion de numero ascii de caracter desde la direccion
				beq  $s3,45,numero_negativo # pregunta si existe un signo menos o negativo
				beq $s3,10,encontro_salto # pregunta si existe un salto de linea

				#convertir caracter a digito entero
				add $a1, $zero, $s3
  				jal character_to_int
  				move $s7, $v0
  				#multiplicar digito entero por la potencia correspondiente de 10
  				addi $a0, $zero, 10 ##Argumento base
				add $a1, $zero, $s5 ## Argumento exponente
				jal pow
				move $s3,$v1 ##Resultado de potencia
				mul $s3,$s3,$s7 # (DIGITO x 10 ^ potencia)
				add $s6,$s6,$s3  #(DIGITO x 10 ^ potencia) + lo anterior
				addi $s5,$s5,1

				continuar_despues_numero_negativo_agregado:
				subi $s2,$s2,1
				b loop_lectura

			encontro_salto:
				bne $k0, 1, agregar_lista
				addi $k0, $zero, 0
				b continuar_despues_numero_negativo_agregado

			numero_negativo:
				sub $s6, $zero, $s6
				addi $k0, $zero, 1
				b agregar_lista

			agregar_lista:
				##ACA DEBO METER EL NUMERO RECIENTEMENTE CREADO EN LA LISTA ENLAZADA
				add $a0, $zero, $s4
				add $a1, $zero, $s6
				jal insertar_inicio
				move $s4,$v0
				addi $k1,$k1,1
				addi $s6,$zero,0 #reiniciar suma del numero total
				addi $s5 $zero,0
				subi $s2,$s2,1

				b loop_lectura

			end_loop_lectura:
				#AGREGAR EL ULTIMO VALOR positivo, debido a que no tiene salto de linea, no entra antes
				bne $s3, 45, positivo
				b true_end_lectura
				positivo:
				add $a0, $zero, $s4
				add $a1, $zero, $s6
				jal insertar_inicio
				move $s4,$v0
				addi $k1,$k1,1
				b true_end_lectura
			true_end_lectura:

			move $s5, $k1
			###############################################################
			# Close the file
			li   $v0, 16       # system call for close file
			move $a0, $s0      # file descriptor to close
			syscall            # close file
			###############################################################


		#Llamar a función (lista debe estar cargada en $a1)
		#
		move $a0,$s5
		jal crear_arreglo_auxiliar
		move $s6, $v0
		
		move $a0, $s4
		li $a1, 0
		addi $a2, $s5,-1
		li $s7,0
		jal merge_sort
		
		
		lw $a0, 0($sp) #archivo  salida
		addi $sp, $sp,4 
		
		##### ESCRITURA DE LISTA ORDENADA EN ARCHIVO ###
		###############################################################
# Open (for writing) a file that does not exist
  li   $v0, 13       # system call for open file
  #move   $a0, $a0     # output file name
  la $a0, fout
  li   $a1, 1        # Open for writing (flags are 0: read, 1: write)
  li   $a2, 0        # mode is ignored
  syscall            # open a file (file descriptor returned in $v0)
  move $s6, $v0      # save the file descriptor 
  ###############################################################
  # Write to file just opened
  ######## ITERAR LA LISTA PARA IMPRIMIR TODAS LAS LINEAS #########
  move $a0, $s4
  move $a1,$s6
  jal dump_archivo
  ###############################################################
  # Close the file 
  li   $v0, 16       # system call for close file
  move $a0, $s6      # file descriptor to close
  syscall            # close file
  ###############################################################
		#Llamado a termino del programa
		b end

		#Terminar el prgrama
		end:
			li $v0,10
			syscall

	#Si la entrada no contiene los suficientes argumentos muestra mensaje de error
	fallo_entrada_argumentos:
		li $v0, 4
		la $a0, fallo_arg
		syscall
		#Llamado a termino del programa
		j end

	#Este procedimiento se encarga de escribir en un archivo de texto
	#una lista enlazada (utiliza el buffer en .data)
	#Entrada:	$a0 -> lista a guardar
	#		$a1 -> file decriptor
	#Salida:	Sin salida
	dump_archivo:
		move $a2, $a0 #aux
		move $k1,$a1 #guardar file decriptor
		addi $sp, $sp,-4
		sw $ra, 0($sp)
		loop_dump_archivo:
			beq $a2,$zero,end_dump_archivo
			#cargar el dato de la lista en a0
			lw $a0,0($a2)
			addi $sp,$sp,-4
			sw $a2, 0($sp)
			#pasarlo a string
			jal int_to_string
			move $t9,$v0 #string representativo en t9
			#imprimir buffer en archivo
			li $v0,15
			move $a0, $k1
			la   $a1, ($t9)   # address of buffer from which to write
			la $t0, buffer
			sub $t0,$t0,$t9
			mul $t0,$t0,-1
			li $t1,13
			sub $t0,$t1,$t0
			move   $a2, $t0
			syscall
			lw $a2, 0($sp)
			addi $sp,$sp,4
			#  aux = aux->sig
			lw $a2, 4($a2)
			b loop_dump_archivo
		end_dump_archivo:
			lw $ra, 0($sp)
			addi $sp, $sp,4
			jr $ra

	#Este procedimiento se encarga de ordenar una lista enlazada, con el algoritmo recursivo de PONER ALGORITMO
	#Entrada: 	$a0-> Direccion a una lista enlazada con los elementos enteros
	#		$a1-> Posicion inicio
	#		$a2-> Posicion final
	#Salida: $v0 Direccion a lista ordenada
	merge_sort:
		bge $a1,$a2, no_entra_merge_sort
		addi $s7,$s7,1
		add $t1,$a1,$a2 # t1= inicio+final
		div $t1,$t1,2 #t1 = (inicio+final)/2
			
		
		addi $sp,$sp,-20 #reserva en el stack
		sw $ra ,0($sp) #direccion antes de llamado
		sw $a0,4($sp) #cabeza lista
		sw $a1,8($sp) #inicio
		sw $a2,12($sp) #fin 
		sw $t1,16($sp) #medio
		move $a0, $a0
		move $a1,$a1 #inicio =inicio
		move $a2,$t1 #fin = medio
		
		jal merge_sort
		
		lw $a0,4($sp)#cabez
		lw $a1,8($sp)#inicio
		lw $a2,12($sp)#fin
		lw $t1, 16($sp)#medio

		
				
		
		addi $sp, $sp,-20
		sw $ra ,0($sp) #direccion antes de llamado
		sw $a0,4($sp) #cabeza lista
		sw $a1,8($sp) #inicio =medio+1
		sw $a2,12($sp) #fin =fin
		sw $t1,16($sp) #guardar medio
		
		move $a0, $a0
		addi $a1, $t1,1
		move $a1,$a1 #inicio =medio+1
		move $a2,$a2 #fin = fin
		
		jal merge_sort
		
					
		lw $a0,4($sp)#cabeza
		lw $a1,8($sp)#incio
		lw $a2,12($sp)#fin
		lw $t1,16($sp)#medio
		addi $sp, $sp,20
		move $a0, $a0
		move $a1,$a1 #inicio=inicio
		move $a3,$a2 #fin = fin
		move $a2, $t1 #medio = medio
		
		jal combinar
		move $v0,$a0
		lw $ra, 0($sp)
		addi $sp,$sp,40
		jr $ra
		no_entra_merge_sort:
		move $v0,$a0
		jr $ra

	#Este procedimiento se encarga de combinar las lista del procedimiento de merge_sort
	#Entrada: 	$a0-> puntero a lista
	#		$a1-> inicio
	#		$a2-> medio
	#		$a3-> final
	#Salida: 	$v0-> puntero a lista
	combinar:
		move $t9, $a0
		move $k0, $a1
		move $k1, $a3
		move $a0, $s5
		
		add $sp, $sp,-12
		sw $a1, 0($sp)
		sw $a2, 4($sp)
		sw $a3, 8($sp)


		move $t0,$s6  #Aux
		move $t1,$a1 #h = inicio
		move $t2,$a1 #i= inicio
		addi $t3,$a2,1 #j = medio+1
		addi $t4,$zero,0 #k = 0
		

		loop_recorre_ambas_sublistas:
			sle  $a0,$t2,$a2 #¿i <= medio ?
			sle  $a1,$t3,$a3 #¿j <= fin ? 
			mul $a0, $a0,$a1 # 1 si lo anterior se cumple
			bne $a0,1,end_loop_recorre_ambas_sublistas #while
			move $a0, $t9 
			move $a1, $t2
			jal dato_en_posicion # Buscar A[i]
			lw $a1, 0($sp)
			lw $a2, 4($sp)
			lw $a3, 8($sp)
			move $t8, $v0 #A[i]
			move $a0,$t9 
			move $a1, $t3
			jal dato_en_posicion #Buscar A[j]
			lw $a1, 0($sp)
			lw $a2, 4($sp)
			lw $a3, 8($sp)
			move $t7,$v0 #A[j]
			sle $a0,$t8,$t7 #¿A[i]<= A[j]?
			bne $a0,1,sino_sublista #if (A[i]>A[j]) goto else
				move $a0, $t0 # t0 es Aux
				move $a1, $t8 # t8 es A[i]
				move $t8, $a2
				move $a2, $t1 # t1 es h
				move $a0, $s6
				jal cambiar_valor_en_p #Aux[h] = A[i]
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)		
				move $t0,$v0 
				move $a2,$t8
				addi $t2,$t2,1 # i=i+1
				b avanzar_h
			sino_sublista:  #else
				move $a0, $t0 # t0 es Aux
				move $a1, $t7 # t7 es A[j]
				move $t8, $a2
				move $a2, $t1 # t1 es h
				move $a0, $s6		
				jal cambiar_valor_en_p
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)
				move $t0,$v0
				move $a2, $t8
				addi $t3,$t3,1 # j =j+1
				b avanzar_h
			avanzar_h:
				addi $t1,$t1,1 # h= h+1
				b  loop_recorre_ambas_sublistas
		end_loop_recorre_ambas_sublistas:
		sgt $a0,$t2,$a2
		beq $a0,0, seguir
			move $t4, $t3
			for_1:
				sne $a0,$t4,$a3 #¿k>fin?
				beq $a0,1,end_for_1
				move $a0, $t9 #A
				move $a1,$t4 # k
				jal dato_en_posicion #Buscar A[k]
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)
				move $t8,$v0 
				move $a0, $t0  # Aux
				move $a1, $t8 # A[k]
				move $t8, $a2
				move $a2, $t1 # h
				move $a0, $s6		
				jal cambiar_valor_en_p
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)
				move $t0,$v0
				move $a2, $t8
				addi $t4,$t4,1 #k=k+1
				addi $t1,$t1,1 #h=h+1
				b for_1

		seguir:
			move $t4, $t2
			for_2:
				sgt $a0,$t4,$a2  #¿k>medio?
				beq $a0,1,end_for_2
				move $a0, $t9 #A
				move $a1,$t4 # k	
				jal dato_en_posicion #Buscar A[k]
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)
				move $t8,$v0 
				move $a0, $t0  # Aux
				move $a1, $t8 # A[k]
				move $t8, $a2
				move $a2, $t1 # h
				move $a0, $s6				
				jal cambiar_valor_en_p							
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)				
				move $t0,$v0
				move $a2, $t8
				addi $t4,$t4,1 #k=k+1
				addi $t1,$t1,1 #h=h+1
				b for_2
		end_for_1:
		end_for_2:
		move $t8,$t9 #L sin cammbios
		move $t0,$t0 #arreglo aux
		move $t4, $k0
			for_3:
				sgt $a0,$t4,$a3
				beq $a0,1,end_for_3
				move $a0, $t0 #Aux
				move $a1,$t4 # k
				move $a0, $s6
				jal obtener_valor_en_p
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)		
				move $t8,$v0
				move $a0, $t9 #A
				move $a1, $t8 #A[k]
				move $t8, $a2
				move $a2, $t4 # k
				jal insertar_posicion #A[k] = Aux[k]
				lw $a1, 0($sp)
				lw $a2, 4($sp)
				lw $a3, 8($sp)
				move $t9,$v0
				move $a2, $t8
				addi $t4,$t4,1 #k=k+1
				b for_3
		end_for_3:
		move $a0,$s6
		move $a1, $s5
		jal vaciar_arreglo
		addi $sp,$sp,12
		move $v0, $t9
		lw $ra, 0($sp)
		addi $sp, $sp,20
		jr $ra


	#Este procedimiento se encarga de crear un arreglo auxiliar de un 
	#tamano dado
	#Entrada: 	$a0-> tamano n
	#Salida:	$v0-> direccion a primer elemento
	crear_arreglo_auxiliar:
		li $v0,9
		mul $a0,$a0,4
		syscall
		jr $ra
		
	#Este procedimiento se encarga de modificar el valor de un arreglo 
	#en una posicion
	#Entrada: 	$a0 -> direccion primer elemento
	#		$a1 -> valor
	#		$a2 -> posicion
	#Salida: 	Sin salida
	cambiar_valor_en_p:
		mul $a2,$a2,4
		add $a0,$a2, $a0
		sw $a1, ($a0)
		jr $ra
	
	#Este procedimiento se encarga de obtener el valor contenido 
	#en una posicion de un arreglo
	#Entrada:	$a0 -> direccion primer elemento
	#		$a1 -> posicion
	#Salida: 	$v0 -> valor obtenido
	obtener_valor_en_p:
		mul $a1,$a1,4
		add $a0,$a1, $a0
		lw $v0, ($a0)
		jr $ra

	#Este procedimiento se encarga de vaciar o volver a 0 los valores de un arreglo
	#Desde una posicion inicial a una posicion final
	#Entrada:	$a0 -> arreglo
	#		$a1 -> posicion inicial
	#		$a2 -> posicion final
	#Salida: 	$v0 -> arreglo modificado
	vaciar_arreglo:
		move $v0, $a0
		for_vaciar_arreglo:
			sgt $t0,$a1,$a2
			beq $t0, 1, end_for_vaciar_arreglo
			sw $zero,($a0)
			addi $a1, $a1, 1
			addi $a0, $a0, 4
			b for_vaciar_arreglo
		end_for_vaciar_arreglo:
		jr $ra

		
	#Esta funcion se encarga de convertir un numero entero de 32 bits de representacion en base 10
	#a un string en ASCII
	#Entrada: 	$a0 -> un numero entero de 32 bits base 10
	#Salida:  	$v0 -> respresentacion string ASCII del número
	int_to_string:
		move $v1, $ra
		move $t0,$a0 #numero
		li $v0,0 # retorno
		li $t2, 10 # base
		la $t9, buffer #string buffer
		addi $t9, $t9,12 # correr indice de escritura en buffer a la ultima posicion
		li $t6, 10
		sb $t6,($t9)
		addi $t9, $t9,-1
		slt $a0, $t0,$zero
		beq $a0,1,negativo_int_string
			addi $k0,$zero,0
			b while_int_to_string
		negativo_int_string:
			addi $k0,$zero,1
			mul $t0,$t0,-1
			b while_int_to_string
		while_int_to_string:
			seq $t1,$t0,$zero
			beq $t1,1, coef_cero #while(num != 0)
			div $t0,$t2 # num/10
			mfhi $a0 #resto
			jal int_to_character
			move $t3,$v0
			
			#insertar al buffer
			sb $t3,($t9)
			#siguiente psicion buffer
			addi $t9,$t9,-1
			mflo $t0 # siguiente = coeficiente
			b while_int_to_string
		coef_cero:
			bne $k0, 1, terminar_int_string
			li $t3,45
			sb $t3,($t9)
			move $v0,$t9
			move $ra, $v1
			jr $ra
		terminar_int_string:
			addi $t9,$t9,1
			move $v0,$t9
			move $ra, $v1
			jr $ra
		
		
	#Esta funcion se encarga de convertir un dígito entero base 10 a su representación de caracter ASCII
	#Entrada:	$a0-> un digito numerico entero
	#Salida:	$v0-> un valor de caracter ASCII
	int_to_character:
		addi $v0, $a0,48
		jr $ra
				
	#Este procedimiento se encarga de convertir un caracter a su representacion decimal
	#Entrada: En $a1 un valor de caracter en código ASCII
	#Salida: En $v0 un valor en representacion decimal para el caracter
	character_to_int:
		blt $a1,48, error_character_to_int
		bgt $a1,57,error_character_to_int
		addi $t0,$zero,47
		addi $v0, $zero, -1
		loop_character_to_int:
			addi $v0,$v0,1
			addi $t0,$t0,1
			bne $a1,$t0,loop_character_to_int
			j end_loop_character_to_int
		error_character_to_int:
			li $v0,4
			la $a0, mensaje_error_character_to_int
			syscall
			li $v0,1
			move $a0,$a1
			syscall
			b end
		end_loop_character_to_int:
			jr $ra

	#Este procedimiento se encarga de obtener la potencia de b^e
	#Entrada: 	$a0-> valor base
	#		$a1-> valor exponente
	#Salida: 	$v1 -> resultado de potencia
	pow:
		addi $t9,$zero,0
		addi $v1, $zero,1
		loop_pow:
			beq $t9,$zero,primer_pow
			mul $v1,$v1,$a0
			volver_primer_pow:
			beq $t9,$a1,end_loop_pow
			addi $t9,$t9,1
			b loop_pow
		end_loop_pow:
			jr $ra
		primer_pow:
			b volver_primer_pow


	

	#Este procedimiento se encarga de insertar un elemento al INICIO de una lista
	#Entrada: 	$a0-> direccion de memoria de la lista
	#	  	$a1 -> dato a guardar
	#Salida: 	$v0-> nueva direccion de memoria de la lista
	insertar_inicio:
		addi $sp, $sp, -12
		sw $ra, 0($sp)
		sw $a0, 4($sp)
		sw $a1, 8($sp)
		jal es_vacia
		beq $v0, 1, lista_vacia_insertar_inicio
		##lista NO vacia
			add $a0, $zero, $a1
			jal crear_nodo

			lw $a0, 4($sp) # $a0 -> puntero primer nodo
			sw $a0, 4($v0) #nuevo->sig = puntero primer nodo
			b end_insertar_inicio

		lista_vacia_insertar_inicio:
		##lista vacia
			add $a0, $zero, $a1
			jal crear_nodo
			b end_insertar_inicio
		end_insertar_inicio:
			lw $t0, 0($sp)
			addi $sp, $sp,12
			jr $t0


	#Este procedidmiento se encarga de crear un nuevo nodo con un dato
	#Entrada: $a0-> dato entero para el nodo
	#Salida: $v0-> Direccion de memoria del nodo
	crear_nodo:
		move $t0,$a0
		addi $v0,$zero,9
		addi $a0,$zero,8
		syscall
		sw $t0, 0($v0) #Nodo->dato = dato_argumento
		sw $zero, 4($v0)#Nodo->sig = null o 0 o zero
		jr $ra


	#Este procedimiento se encarga de reconocer si una lista está vacia
	#Entrada: $a0-> direccion de memoria de la lista
	#Salida: $v0-> un valor 1 o 0. 1 si esta vacia 0 si no esta vacia
	es_vacia:
		beq $a0, $zero, lista_vacia
		addi $v0,$zero, 0
		jr $ra
		lista_vacia:
			addi $v0, $zero, 1
			jr $ra
	
	#Este procedimiento se encarga de insertar un elemento al FINAL de una lista
	#Entrada: 	$a0-> direccion de memoria de la lista
	#	  	$a1 -> dato a guardar
	#Salida: 	$v0-> nueva direccion de memoria de la lista
	insertar_final:
		addi, $sp, $sp,-4
		sw $ra,0($sp)
		move $k1,$a0
		move $a0, $a0
		jal es_vacia
		beq $v0, 1, lista_vacia_insertar_final
		##lista NO vacia
			add $a0, $zero, $a1
			jal crear_nodo
			move $t6, $v0

			move $t2, $k1
			loop_insertar_final:
				lw $t0, 4($t2)
				beq $t0,$zero,end_loop_insertar_final
					lw $t2, 4($t2)
				b loop_insertar_final
			end_loop_insertar_final:
				sw $t6, 4($t2)
				b end_insertar_final

		lista_vacia_insertar_final:
		##lista vacia
			add $a0, $zero, $a1
			jal crear_nodo
			move $a0, $t8
			lw $ra,0($sp)
			addi $sp,$sp,4
			jr $ra
			
		end_insertar_final:
			move $v0,$k1
			lw $ra,0($sp)
			addi $sp,$sp,4
			jr $ra
	
	#Este procedimiento se encarga de mostrar por panatalla la lista enlazada
	#Entrada:	$a0->direccion de memoria de lista
	#Salida:	Sin salida
	mostrar_lista:
		move $a2, $a0
		loop_mostrar_lista:
			beq $a2,$zero,end_mostrar_lista
			li $v0,1
			lw $a0,0($a2)
			syscall
			li $v0,4
			la $a0,salto_linea
			syscall
			lw $a2, 4($a2)
			b loop_mostrar_lista
		end_mostrar_lista:
			jr $ra
	
	#Este procemidiento se ecnarga de generar una lista enlazada de tamaño dado, inicializada en ceros
	#Entrada: 	$a0-> n cantidad de nodos
	#Salida:	$v0 -> puntero a la cabeza de esta lista
	crear_lista_n_nodos:
		addi, $sp, $sp,-4
		sw $ra,0($sp)
		addi $t6, $zero, 0
		addi $t5, $zero, 0
		add $t7, $zero, $a0
		loop_crear_lista_n_nodos:
			bge $t5,$t7, end_loop_crear_lista_n_nodos
			move $a0, $t6
			li $a1,0
			jal insertar_final
			move $t6,$v0
			addi $t5, $t5,1
			b loop_crear_lista_n_nodos
			
		end_loop_crear_lista_n_nodos:
			lw $ra,0($sp)
			addi $sp,$sp,4
			move $v0, $t6
			jr $ra
			
			
	#Este procedimiento se encarga de obtener un dato en una posicion dada de una lista enlazada
	#Entrada: 	$a0-> puntero a cabeza de lista
	#		$a1-> posicion
	#Salida: 	$v0-> dato obtenido
	dato_en_posicion:
		li $k1,0
		loop_dato_en_posicion:
			blt $a1,0,posicion_negativa_dato_en_posicion
			bgt $k1,$a1, posicion_mayor_dato_en_posicion
			beq $k1,$a1,  encontro_dato_en_posicion
			addi $k1,$k1,1
			lw $a0, 4($a0)
			b loop_dato_en_posicion
		encontro_dato_en_posicion:
			lw $a1, 0($a0)
			move $v0, $a1
			jr $ra
		posicion_negativa_dato_en_posicion:
			li $v0,4
			la $a0, error_posicion_negativa_dato_en_posicion
			syscall
			b end
		posicion_mayor_dato_en_posicion:
			li $v0,4
			la $a0, error_posicion_mayor_dato_en_posicion
			syscall
			b end
			
			
	#Este procedimiento se encarga de instroducir un valor a una lista enlazada en una posicion dada
	#(Para este procedimiento se requiere una lista inicializada con nodos creados, mediante el procedimiento crear_lista_n_nodos)
	#Entrada: 	$a0-> puntero cabeza lista
	#		$a1-> valor a ingresar
	#		$a2-> posicion de ingreso
	#Salida: 	$v0-> puntero a cabeza de nueva lista
	insertar_posicion:
		move $t5,$a0
		li $k1,0
		loop_insertar_posicion:
			blt $a2,0,posicion_negativa_insertar_posicion
			bgt $k1,$a2,posicion_mayor_insertar_posicion
			beq $k1,$a2, encontro_posicion
			addi $k1,$k1,1
			lw $t5, 4($t5)
			b loop_insertar_posicion
		encontro_posicion:
			sw $a1, 0($t5)
			move $v0, $a0
			jr $ra
		posicion_negativa_insertar_posicion:
			li $v0,4
			la $a0, error_posicion_negativa_insertar_posicion
			syscall
			b end
		posicion_mayor_insertar_posicion:
			li $v0,4
			la $a0, error_posicion_mayor_insertar_posicion
			syscall
			b end
	
	