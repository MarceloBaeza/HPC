#Primer parcial High Performance Computing
##CPU v/s GPU
###Multiplicación de matrices utilizando programación secuencial y en paralelo

													Integrantes: Marcelo Baeza
																 Eduardo López

---

#Introducción 
La concurrencia es cuando existen varios procesos en un mismo tiempo.

La concurrencia se refiere al uso de varios procesadores sin embargo la concurrencia es “simulada”, esto quiere decir que a pesar de parecer que varios procesos se están ejecutando de manera simultánea, el proceso concurrente solo toma cada proceso durante un intervalo de tiempo muy pequeño, alternando entre cada uno en ejecución.
Los procesos concurrentes tienden a llevar muchas veces errores como una sección critica donde, 2 o más procesos requieren la utilización del mismo recurso, pero todos estos procesos esperan a que el otro proceso que los sigue deje de utilizar o pedir el mismo recurso. Para esto existe la exclusión mutua donde se deben implementar protocolos de software para que el recurso pedido por varios procesos pueda seguir un orden “normal”.
Para el presente informe, se presentará la diferencia entre aplicar procesos de manera secuencial y concurrente para el problema de multiplicación de matrices.
Se presentará la resolución de una multiplicación de matrices de manera secuencial, es decir de tipo host, donde se utilizará la CPU para desarrollar las operaciones con una cantidad de núcleos definida y una multiplicación de matrices de tipo device, donde se utiliza la GPU la cual posee miles de núcleos.
Para el presente trabajo se desarrollará un versus entre computo secuencial vs paralelo, tanto en CPU como GPU.

---

#Desarrollo

Antes de comenzar a comparar ambas ejecuciones para demostrar que es mejor y por qué, primero cabe destacar que se debe entender la diferencia entre CPU y GPU. Para esto se presentará la siguiente tabla mostrando sus diferencias y similitudes.

![](http://puu.sh/rpJzI/7502f434a7.png)
[Imagen1. Diseño de CPU vs diseño GPU](http://puu.sh/rpJzI/7502f434a7.png)

La gran y diferencia más relevante entre CPU y GPU es la cantidad de núcleos que dispone cada una.



![](http://puu.sh/rpK6w/6b531014b4.png)

 [Imagen2. Cantidad de núcleos por arquitectura](http://puu.sh/rpK6w/6b531014b4.png)

La finalidad de comparar ambas arquitecturas y hacer uso de estos es para optimización de recursos, en el caso de estudio una multiplicación de matrices tiende a poseer un cálculo exponencial, haciendo que el desarrollo de este de manera secuencial se vuelva inviable para cálculos colosales. Aquí es donde entra en juego la GPU, ya que utilizando hilos y la cantidad de núcleos que posee, puede desarrollar operaciones colosales, como la multiplicación de matrices de tamaños extremadamente altos, en relativamente muy pocos segundos.

##Caso de estudio

Para el caso de estudio se comparan tamaños de matrices distintas, es decir, A * B = C, donde A y B son NxM y KxL respectivamente.
Estas matrices serán multiplicadas tanto en CPU como en GPU. Para la multiplicación de matrices en CPU, en este caso de tipo host, el desarrollo será el ya convencional conocido por todos. Donde A*B se multiplican valor por valor hasta obtener C. 
Y la ejecución en GPU será utilizando el kernel es decir de tipo device donde se utilizará la técnica de tiles. 


###Metodo utilizando tiles

![](http://puu.sh/rpK5u/6be2fc9dc1.png)
[Imagen3. Ejemplo método tiles](http://puu.sh/rpK5u/6be2fc9dc1.png)

La idea general es:

-	Dividir la memoria global en tiles.
-	Hacer que el computo de cada hilo sea sobre un tile o una pequeña parte de este, durante cierto periodo de tiempo.


Forma de cálculo matricial utilizando tiles:

![](http://puu.sh/rpK4l/e996ce58f5.png)
 [Imagen4. Ejemplo de cálculo utilizando tiles](http://puu.sh/rpK4l/e996ce58f5.png)

Existen 2 matrices tal que esta es dividida en secciones las cuales son tomadas, en este caso las primeras 4 posiciones de cada sección dividida. Cada una de estas secciones va a memoria compartida donde el hilo puede acceder para hacer la respectiva operación.

![](http://puu.sh/rpK3B/ed0ea56d14.png)
 [Imagen5.Ejemplo de cálculo utilizando tiles](http://puu.sh/rpK3B/ed0ea56d14.png)

Una vez accede el hilo a la memoria compartida, es decir al Tile respectivo, esta toma los valores ya ingresados de las matrices anteriores, los calcula y los ingresa en las mismas posiciones, pero esta vez en la matriz resultante.

###Desarrollo secuencial v/s paralelo utilizando Tiles

Para el presente caso de estudio se ha desarrollado un programa en lenguaje C/C++ el cual calcula la multiplicación de matrices, realizando su procesamiento tanto en CPU como en GPU. Los valores estudiados son los siguientes:

![](http://puu.sh/rrTcJ/bbe1b6a757.png)

 [Imagen6. Tiempos de procesamiento CPU/GPU](hhttp://puu.sh/rrTcJ/bbe1b6a757.png)

Se puede notar como el tiempo en CPU aumenta radicalmente, esto es debido a que la operación es realizada paso por paso, es decir, cada multiplicación fila x columna es desarrollada una a la vez hasta completar la matriz resultante. 

![](http://puu.sh/rqfUg/08e8fb4c0d.png)

 [Imagen7. Velocidad de procesamiento en CPU](http://puu.sh/rqfUg/08e8fb4c0d.png)

A diferencia de la GPU, el proceso de multiplicar matrices es desarrollado con hilos donde además se trabaja según la cantidad de núcleos que este posee. Una sección de la matriz es tomada y llevada a memoria compartida donde cada hilo accede a esta memoria compartida y realiza el cálculo pertinente. (véase Imagen4 e Imagen5), además de que la ejecución de hilos es de manera paralela por lo que mientras un hilo realiza una operación existe otro hilo accediendo a memoria compartida para realizar otra operación de la matriz. 

![](http://puu.sh/rrTlO/005073baa0.png)

 [Imagen8. Velocidad de procesamiento en GPU](http://puu.sh/rrTlO/005073baa0.png)

####Tiempos durante copia de datos tanto de host a device como de device a host

![](http://puu.sh/rqfTd/ce3261e41b.png)

 [Imagen9. Tiempos durante traspaso de datos entre host y device.]()

El proceso que mas toma tiempo al momento de desarrollar cálculos en GPU es el traspaso de datos de device al host.

####Comparación de tiempos de procesamiento en CPU v/s GPU

![](http://puu.sh/rqcan/5572da412c.png)

 [Imagen10. Velocidad de procesamiento CPU v/s GPU](http://puu.sh/rqcan/5572da412c.png)

Como se puede observar en la gráfica anterior el salto exponencial de tiempo de procesamiento de CPU ocurre en cierto momento, donde el tamaño de la matriz empieza a ser superior a 500 filas o columnas. Si se presta atención a la tabla ya antes presentada se puede observar que los valores pequeños de una matriz son calculados más rápidamente por CPU que GPU esto se debe a que el cálculo es secuencial y al ser pocos valores el desempeño tiende a ser mejor , en cambio la GPU debe crear el espacio de memoria compartida , asignar la cantidad de hilos , el tamaño del Grid y del Bloque respectivo para su ejecución, este proceso a pesar de ser prácticamente atómico a nivel de tiempo (en segundos), a nivel de maquina consume tiempo.

####Aceleración del procesamiento por hardware

En informática, la aceleración por hardware es el uso del hardware para realizar alguna función más rápido de lo que es posible usando software ejecutándose en una CPU de propósito general.
El hardware que realiza la aceleración, cuando se encuentra en una unidad separada de la CPU, es denominado acelerador por hardware, o a menudo más específicamente como un acelerador gráfico o unidad de coma flotante, etc. Estos términos, sin embargo, son antiguos y se han sustituido por términos menos descriptivos como "placa de vídeo" o "placa gráfica".
Ahora bien, para obtener la aceleración respectiva en este caso de estudio solo basta dividir la velocidad del tiempo de procesamiento en CPU por tiempo de procesamiento en GPU.

![](http://puu.sh/rrTbW/13dc602c1b.png)

 [Imagen11. Tabla de aceleración por hardware.](http://puu.sh/rrTbW/13dc602c1b.png)

Como puede observarse en la tabla la aceleración va aumentando a medida que el tamaño de la matriz aumenta, para una mejor percepción véase el siguiente gráfico.

![](http://puu.sh/rrT8y/9cb860e120.png)

 [Imagen12. Aceleración por hardware](http://puu.sh/rrT8y/9cb860e120.png)

Como puede observarse en el gráfico anterior la aceleración indica que el procesamiento en GPU es bastante satisfactorio para procesamiento de cálculos colosales sin embargo esto depende de que es lo que se desea calcular. 
La GPU hoy en día cumple la mayor parte de sus funcionalidades a nivel de calidad gráfica, todo lo que se puede observar, como gran ejemplo los videojuegos, para cálculos donde el desempeño debe ser realizado a nivel de pixel.

---
#Conclusiones

Como ya se ha mencionado anteriormente en el presente caso de estudio la CPU y GPU poseen desempeños totalmente diferentes a medida que la complejidad del cálculo aumenta, donde la GPU gracias a la cantidad de núcleos que posee puede realizar estos procesos de manera más rápida que la CPU. Sin embargo, la CPU tiende a tener un mejor desempeño para procesamiento secuencial más pequeño, es decir si poseemos un programa que debe hacer grandes cálculos sea cual sea este, lo ideal es juntar tanto CPU como GPU ya que el procesamiento secuencial puede ser desarrollado de manera más eficiente en CPU y los cálculos extremadamente grandes pueden ser desarrollados de manera más rápida por la GPU, y de esta manera obtener un mejor desempeño y optimizar la aceleración de hardware es decir, utilizar todos los recursos que poseemos al momento programar.

---

#Referencias

https://es.wikipedia.org/wiki/Aceleraci%C3%B3n_por_hardware
https://blogs.nvidia.com/blog/2009/12/16/whats-the-difference-between-a-cpu-and-a-gpu/
http://www.nvidia.com/object/what-is-gpu-computing.html