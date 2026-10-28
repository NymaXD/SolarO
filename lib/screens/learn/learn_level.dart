/// Modelo de datos del módulo educativo (niveles, lecciones y videos).
///
/// Contenido basado en la investigación del módulo educativo.
/// El progreso se guarda localmente y está listo para sincronizarse con el
/// backend (GET /learn/progress, POST /learn/progress).
class LearnLevel {
  final String id;       // nivel_1, nivel_2, nivel_3
  final String title;    // Nivel 1 - Básico
  final String subtitle; // objetivo corto
  final List<LearnLesson> lessons;
  final int completed;

  const LearnLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lessons,
    this.completed = 0,
  }) : total = lessons.length;

  final int total;

  double get progress => total == 0 ? 0 : completed / total;
  bool get isCompleted => total > 0 && completed == total;

  LearnLevel copyWith({int? completed}) => LearnLevel(
        id: id,
        title: title,
        subtitle: subtitle,
        lessons: lessons,
        completed: completed ?? this.completed,
      );
}

class LearnLesson {
  final String id;
  final String title;
  final String type; // 'video' | 'lectura'
  final String? youtubeId;
  final String? contenido; // texto completo de la lectura
  final bool done;

  const LearnLesson({
    required this.id,
    required this.title,
    required this.type,
    this.youtubeId,
    this.contenido,
    this.done = false,
  });

  bool get isVideo => type == 'video';

  LearnLesson copyWith({bool? done}) => LearnLesson(
        id: id,
        title: title,
        type: type,
        youtubeId: youtubeId,
        contenido: contenido,
        done: done ?? this.done,
      );
}

/// Contenido de los 3 niveles.
class LearnData {
  static List<LearnLevel> levels() => [
        LearnLevel(
          id: 'nivel_1',
          title: 'Nivel 1 - Básico',
          subtitle: 'Qué es la energía solar y cómo funciona',
          lessons: [
            LearnLesson(
              id: 'l1a',
              title: '¿Qué es la energía solar?',
              type: 'lectura',
              contenido:
                  'La energía solar es una fuente de energía renovable, es decir, que no se agota, '
                  'porque viene del Sol. Consiste en aprovechar la luz solar para producir electricidad.\n\n'
                  'Es limpia y silenciosa: no quema combustibles ni emite gases mientras genera '
                  'electricidad. En Colombia, además, el recurso solar es abundante durante todo el año.',
            ),
            LearnLesson(
              id: 'l1b',
              title: '¿Cómo funciona?',
              type: 'lectura',
              contenido:
                  'La luz del Sol está formada por partículas diminutas llamadas fotones. Cuando estos '
                  'fotones llegan a un panel solar, le entregan su energía a los electrones del material '
                  'del panel. Con esa energía extra, los electrones se ponen en movimiento y viajan por '
                  'unas tiras metálicas que tiene el panel. Ese movimiento de electrones es lo que '
                  'llamamos corriente eléctrica.\n\n'
                  'Por último, un aparato llamado inversor transforma esa corriente a la que usamos en '
                  'casa, y así podemos encender luces, cargar el celular o hacer funcionar '
                  'electrodomésticos.',
            ),
            LearnLesson(
              id: 'l1c',
              title: 'Piezas de una instalación solar',
              type: 'lectura',
              contenido:
                  '• Panel solar: agrupa varias celdas protegidas por una capa que deja pasar la luz y '
                  'las cuida de la humedad y el polvo.\n\n'
                  '• Inversor: el panel produce corriente continua; el inversor la convierte en corriente '
                  'alterna, la que usamos en casa.\n\n'
                  '• Batería: guarda electricidad para la noche o los días nublados.\n\n'
                  'La instalación también puede apoyarse en la red eléctrica.',
            ),
            LearnLesson(
              id: 'l1v1',
              title: 'Video: ¿Qué es la energía solar?',
              type: 'video',
              youtubeId: 'TVAhIa8oaZQ',
            ),
            LearnLesson(
              id: 'l1v2',
              title: 'Video: Cómo funcionan los paneles',
              type: 'video',
              youtubeId: 'Y2f1xIuxgTE',
            ),
          ],
        ),
        LearnLevel(
          id: 'nivel_2',
          title: 'Nivel 2 - Intermedio',
          subtitle: 'Paneles solares, energía en Colombia y ahorro en casa',
          lessons: [
            LearnLesson(
              id: 'l2a',
              title: 'Cómo funcionan los paneles solares',
              type: 'lectura',
              contenido:
                  'Los paneles solares son módulos que aprovechan la luz del Sol para producir '
                  'electricidad. Cada panel está formado por muchas celdas solares, hechas de materiales '
                  'semiconductores, sobre todo silicio.\n\n'
                  'Cuando los fotones chocan con la celda, le dan energía a los electrones y los sueltan '
                  'de sus átomos. Los electrones se acumulan en un lado (carga negativa) y dejan el otro '
                  'con carga positiva; esa diferencia empuja a los electrones a moverse y se genera '
                  'corriente eléctrica.\n\n'
                  'Esta corriente es continua (DC) y solo se produce mientras hay luz. Por eso muchos '
                  'sistemas usan una batería que guarda la energía sobrante para usarla cuando ya no hay sol.',
            ),
            LearnLesson(
              id: 'l2b',
              title: 'kW y kWh',
              type: 'lectura',
              contenido:
                  '• kW (kilovatio) mide potencia: qué tan fuerte es el sol o un aparato en un instante. '
                  'Es como la velocidad de un carro.\n\n'
                  '• kWh (kilovatio-hora) mide energía: cuánto se acumula durante un tiempo. Es como los '
                  'kilómetros recorridos.\n\n'
                  'El recibo de luz se mide en kWh, y la radiación solar de un lugar se expresa en kWh '
                  'por metro cuadrado al día (kWh/m²/día).\n\n'
                  '4,5 kWh/m² al día equivale a recibir el sol "a tope" durante unas 4,5 horas cada día. '
                  'A eso se le llama horas sol pico.',
            ),
            LearnLesson(
              id: 'l2c',
              title: 'El recurso solar en Colombia',
              type: 'lectura',
              contenido:
                  '• Promedio nacional: cerca de 4,5 kWh/m² al día, superior al promedio mundial de 3,9.\n\n'
                  '• Poca variación durante el año: por estar cerca del ecuador, no hay estaciones que '
                  'reduzcan la producción de forma marcada.\n\n'
                  '• La Guajira y el Caribe: son las zonas que más radiación reciben. La Guajira presenta '
                  'cerca de 6,0 kWh/m² al día.\n\n'
                  '• Datos locales: los promedios regionales son una guía. La radiación real depende de '
                  'la ciudad, la orientación del techo, la sombra y el clima del sitio.',
            ),
            LearnLesson(
              id: 'l2d',
              title: 'Cómo gastar menos electricidad en casa',
              type: 'lectura',
              contenido:
                  'La energía más barata es la que no se consume. Reducir el consumo primero significa '
                  'que, si luego se instalan paneles, se necesitarán menos.\n\n'
                  '• Nevera (cerca del 30% del gasto): mantenerla entre 2 y 6 °C, lejos del horno y la '
                  'lavadora, y abrirla lo menos posible.\n'
                  '• Etiqueta de eficiencia: las clases A, B y C son de bajo consumo; F y G de alto consumo.\n'
                  '• Televisor: los LED gastan 25% menos que los LCD y 40% menos que los de plasma.\n'
                  '• Consumo fantasma: los equipos conectados aunque estén apagados gastan entre 5% y 8%. '
                  'Desconectarlos puede ahorrar cerca del 10% mensual.\n'
                  '• Lavadora: usar ciclos cortos, agua fría y carga completa.\n'
                  '• Horarios: usar los aparatos en horario valle y evitar el pico entre 6 p. m. y 8 p. m.\n'
                  '• Luz natural y LED: aprovechar la luz del día y usar bombillos LED.',
            ),
            LearnLesson(
              id: 'l2v1',
              title: 'Video: Paneles solares y ahorro',
              type: 'video',
              youtubeId: 'q5bMAz4NK0c',
            ),
            LearnLesson(
              id: 'l2v2',
              title: 'Video: Energía solar en Colombia',
              type: 'video',
              youtubeId: 'jO8HBDaok5l',
            ),
            LearnLesson(
              id: 'l2v3',
              title: 'Video: Cálculo de consumo',
              type: 'video',
              youtubeId: 'BbIUE5xr65Q',
            ),
          ],
        ),
        LearnLevel(
          id: 'nivel_3',
          title: 'Nivel 3 - Avanzado',
          subtitle: 'Del efecto fotovoltaico al cálculo del consumo',
          lessons: [
            LearnLesson(
              id: 'l3a',
              title: 'Cálculo de kWh/mes',
              type: 'lectura',
              contenido:
                  'kWh/mes = (potencia (W) × horas al día × días a la semana × cantidad × 4,345) / 1000\n\n'
                  '1. Busca la potencia (W) en la etiqueta del aparato.\n'
                  '2. Anota cuánto lo usas: horas al día y días a la semana.\n'
                  '3. Cuenta cuántos tienes iguales.\n'
                  '4. Multiplica todo y luego por 4,345 (las semanas promedio de un mes).\n'
                  '5. Divide entre 1000 para pasar de vatios a kilovatios y obtener kWh.\n\n'
                  'Ejemplo: un televisor de 100 W, 5 horas al día, 7 días a la semana:\n'
                  '(100 × 5 × 7 × 1 × 4,345) / 1000 ≈ 15,2 kWh al mes.\n\n'
                  'Repite esto con cada aparato y suma los resultados.',
            ),
            LearnLesson(
              id: 'l3b',
              title: 'Dimensionar paneles solares',
              type: 'lectura',
              contenido:
                  'Con el total mensual puedes estimar cuántos kW de paneles necesitas.\n\n'
                  'kW de paneles ≈ kWh al día ÷ (horas sol pico × 0,8)\n\n'
                  'Por ejemplo, 150 kWh/mes son 5 kWh/día; 5 ÷ 4,5 ÷ 0,8 ≈ 1,4 kW.\n\n'
                  'Es solo un orden de magnitud, porque el 0,8 representa pérdidas típicas y varía según '
                  'cada instalación.',
            ),
            LearnLesson(
              id: 'l3c',
              title: 'Radiación y horas sol pico',
              type: 'lectura',
              contenido:
                  '• Radiación en Colombia: promedio de 4,5 kWh/m² al día. En La Guajira llega a cerca de 6,0.\n'
                  '• Promedio mundial: unos 3,9 kWh/m² al día.\n'
                  '• Unidad: la radiación diaria se expresa en kWh/m² por día. Si ves kW/m², es potencia, '
                  'no energía diaria.\n'
                  '• Horas sol pico: 4,5 kWh/m² al día equivale a unas 4,5 horas de sol "a tope" cada día.',
            ),
            LearnLesson(
              id: 'l3v1',
              title: 'Video: Efecto fotovoltaico',
              type: 'video',
              youtubeId: 'L3tPufMH071',
            ),
            LearnLesson(
              id: 'l3v2',
              title: 'Video: Cálculo avanzado de consumo',
              type: 'video',
              youtubeId: 'nca2Lt-BS3U',
            ),
          ],
        ),
      ];
}
