import '../../theme/lang.dart';

/// Modelo de datos del módulo educativo (niveles, lecciones y videos).
///
/// El contenido está en español e inglés. [LearnData.levels] elige el idioma
/// activo (`AppLang.current`) cada vez que se construye, por lo que cambiar de
/// idioma actualiza los títulos y las lecturas sin recargar la app.
///
/// [LearnLesson.number] es la posición 1..N dentro del nivel y coincide con el
/// campo `leccion` que espera el backend (`GET/POST /learn/progress`).
class LearnLevel {
  final int number; // 1, 2, 3 (campo `nivel` del backend)
  final String id; // nivel_1, nivel_2, nivel_3
  final String title;
  final String subtitle;
  final List<LearnLesson> lessons;
  final int completed;

  const LearnLevel({
    required this.number,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lessons,
    this.completed = 0,
  }) : total = lessons.length;

  final int total;

  double get progress => total == 0 ? 0 : completed / total;
  bool get isCompleted => total > 0 && completed == total;

  LearnLevel copyWith({int? completed, List<LearnLesson>? lessons}) =>
      LearnLevel(
        number: number,
        id: id,
        title: title,
        subtitle: subtitle,
        lessons: lessons ?? this.lessons,
        completed: completed ?? this.completed,
      );

  /// Aplica el conjunto de lecciones completadas que devuelve el backend.
  LearnLevel withProgress(Set<int> completedNumbers) {
    final updated = lessons
        .map((l) => l.copyWith(done: completedNumbers.contains(l.number)))
        .toList();
    return copyWith(
      lessons: updated,
      completed: updated.where((l) => l.done).length,
    );
  }
}

class LearnLesson {
  final int number; // 1..N dentro del nivel (campo `leccion` del backend)
  final String id;
  final String title;
  final String type; // 'video' | 'lectura'
  final String? youtubeId;
  final String? contenido; // texto completo de la lectura
  final bool done;

  const LearnLesson({
    required this.number,
    required this.id,
    required this.title,
    required this.type,
    this.youtubeId,
    this.contenido,
    this.done = false,
  });

  bool get isVideo => type == 'video';

  LearnLesson copyWith({bool? done}) => LearnLesson(
        number: number,
        id: id,
        title: title,
        type: type,
        youtubeId: youtubeId,
        contenido: contenido,
        done: done ?? this.done,
      );
}

/// Contenido de los 3 niveles en el idioma activo.
class LearnData {
  static List<LearnLevel> levels() {
    final english = AppLang.current == 'en';
    return _specs
        .map(
          (s) => LearnLevel(
            number: s.number,
            id: s.id,
            title: english ? s.titleEn : s.titleEs,
            subtitle: english ? s.subtitleEn : s.subtitleEs,
            lessons: s.lessons
                .map(
                  (l) => LearnLesson(
                    number: l.number,
                    id: l.id,
                    title: english ? l.titleEn : l.titleEs,
                    type: l.type,
                    youtubeId: l.youtubeId,
                    contenido: english ? l.contentEn : l.contentEs,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Nivel por número (1..3). Útil para reconstruir el detalle al cambiar de
  /// idioma sin conservar textos viejos en el estado.
  static LearnLevel level(int number) =>
      levels().firstWhere((l) => l.number == number);
}

class _LessonSpec {
  final int number;
  final String id;
  final String type;
  final String? youtubeId;
  final String titleEs;
  final String titleEn;
  final String? contentEs;
  final String? contentEn;

  const _LessonSpec({
    required this.number,
    required this.id,
    required this.type,
    this.youtubeId,
    required this.titleEs,
    required this.titleEn,
    this.contentEs,
    this.contentEn,
  });
}

class _LevelSpec {
  final int number;
  final String id;
  final String titleEs;
  final String titleEn;
  final String subtitleEs;
  final String subtitleEn;
  final List<_LessonSpec> lessons;

  const _LevelSpec({
    required this.number,
    required this.id,
    required this.titleEs,
    required this.titleEn,
    required this.subtitleEs,
    required this.subtitleEn,
    required this.lessons,
  });
}

const List<_LevelSpec> _specs = [
  _LevelSpec(
    number: 1,
    id: 'nivel_1',
    titleEs: 'Nivel 1 - Básico',
    titleEn: 'Level 1 - Beginner',
    subtitleEs: 'Qué es la energía solar y cómo funciona',
    subtitleEn: 'What solar energy is and how it works',
    lessons: [
      _LessonSpec(
        number: 1,
        id: 'l1a',
        type: 'lectura',
        titleEs: '¿Qué es la energía solar?',
        titleEn: 'What is solar energy?',
        contentEs:
            'La energía solar es una fuente de energía renovable, es decir, que no se agota, '
            'porque viene del Sol. Consiste en aprovechar la luz solar para producir electricidad.\n\n'
            'Es limpia y silenciosa: no quema combustibles ni emite gases mientras genera '
            'electricidad. En Colombia, además, el recurso solar es abundante durante todo el año.',
        contentEn:
            'Solar energy is a renewable energy source, meaning it does not run out, because it '
            'comes from the Sun. It consists of using sunlight to produce electricity.\n\n'
            'It is clean and silent: it does not burn fuels or emit gases while generating '
            'electricity. In Colombia, the solar resource is also abundant throughout the year.',
      ),
      _LessonSpec(
        number: 2,
        id: 'l1b',
        type: 'lectura',
        titleEs: '¿Cómo funciona?',
        titleEn: 'How does it work?',
        contentEs:
            'La luz del Sol está formada por partículas diminutas llamadas fotones. Cuando estos '
            'fotones llegan a un panel solar, le entregan su energía a los electrones del material '
            'del panel. Con esa energía extra, los electrones se ponen en movimiento y viajan por '
            'unas tiras metálicas que tiene el panel. Ese movimiento de electrones es lo que '
            'llamamos corriente eléctrica.\n\n'
            'Por último, un aparato llamado inversor transforma esa corriente a la que usamos en '
            'casa, y así podemos encender luces, cargar el celular o hacer funcionar '
            'electrodomésticos.',
        contentEn:
            'Sunlight is made up of tiny particles called photons. When these photons reach a '
            'solar panel, they transfer their energy to the electrons in the panel material. With '
            'that extra energy, the electrons start moving and travel through metal strips on the '
            'panel. That movement of electrons is what we call electric current.\n\n'
            'Finally, a device called an inverter converts that current into the one we use at '
            'home, so we can turn on lights, charge our phones or run household appliances.',
      ),
      _LessonSpec(
        number: 3,
        id: 'l1c',
        type: 'lectura',
        titleEs: 'Piezas de una instalación solar',
        titleEn: 'Parts of a solar installation',
        contentEs:
            '• Panel solar: agrupa varias celdas protegidas por una capa que deja pasar la luz y '
            'las cuida de la humedad y el polvo.\n\n'
            '• Inversor: el panel produce corriente continua; el inversor la convierte en corriente '
            'alterna, la que usamos en casa.\n\n'
            '• Batería: guarda electricidad para la noche o los días nublados.\n\n'
            'La instalación también puede apoyarse en la red eléctrica.',
        contentEn:
            '• Solar panel: groups several cells protected by a layer that lets light through and '
            'shields them from moisture and dust.\n\n'
            '• Inverter: the panel produces direct current; the inverter converts it into '
            'alternating current, which is what we use at home.\n\n'
            '• Battery: stores electricity for the night or cloudy days.\n\n'
            'The installation can also rely on the power grid.',
      ),
      _LessonSpec(
        number: 4,
        id: 'l1v1',
        type: 'video',
        youtubeId: 'TVAhIa8oaZQ',
        titleEs: 'Video: ¿Qué es la energía solar?',
        titleEn: 'Video: What is solar energy?',
      ),
      _LessonSpec(
        number: 5,
        id: 'l1v2',
        type: 'video',
        youtubeId: 'Y2f1xIuxgTE',
        titleEs: 'Video: Cómo funcionan los paneles',
        titleEn: 'Video: How panels work',
      ),
    ],
  ),
  _LevelSpec(
    number: 2,
    id: 'nivel_2',
    titleEs: 'Nivel 2 - Intermedio',
    titleEn: 'Level 2 - Intermediate',
    subtitleEs: 'Paneles solares, energía en Colombia y ahorro en casa',
    subtitleEn: 'Solar panels, energy in Colombia and saving at home',
    lessons: [
      _LessonSpec(
        number: 1,
        id: 'l2a',
        type: 'lectura',
        titleEs: 'Cómo funcionan los paneles solares',
        titleEn: 'How solar panels work',
        contentEs:
            'Los paneles solares son módulos que aprovechan la luz del Sol para producir '
            'electricidad. Cada panel está formado por muchas celdas solares, hechas de materiales '
            'semiconductores, sobre todo silicio.\n\n'
            'Cuando los fotones chocan con la celda, le dan energía a los electrones y los sueltan '
            'de sus átomos. Los electrones se acumulan en un lado (carga negativa) y dejan el otro '
            'con carga positiva; esa diferencia empuja a los electrones a moverse y se genera '
            'corriente eléctrica.\n\n'
            'Esta corriente es continua (DC) y solo se produce mientras hay luz. Por eso muchos '
            'sistemas usan una batería que guarda la energía sobrante para usarla cuando ya no hay sol.',
        contentEn:
            'Solar panels are modules that use sunlight to produce electricity. Each panel is made '
            'up of many solar cells, made from semiconductor materials, mainly silicon.\n\n'
            'When photons hit the cell, they give energy to the electrons and release them from '
            'their atoms. Electrons build up on one side (negative charge) and leave the other '
            'side with a positive charge; that difference pushes the electrons to move and '
            'generates electric current.\n\n'
            'This current is direct current (DC) and is only produced while there is light. That '
            'is why many systems use a battery that stores the surplus energy to use it when there '
            'is no sun.',
      ),
      _LessonSpec(
        number: 2,
        id: 'l2b',
        type: 'lectura',
        titleEs: 'kW y kWh',
        titleEn: 'kW and kWh',
        contentEs:
            '• kW (kilovatio) mide potencia: qué tan fuerte es el sol o un aparato en un instante. '
            'Es como la velocidad de un carro.\n\n'
            '• kWh (kilovatio-hora) mide energía: cuánto se acumula durante un tiempo. Es como los '
            'kilómetros recorridos.\n\n'
            'El recibo de luz se mide en kWh, y la radiación solar de un lugar se expresa en kWh '
            'por metro cuadrado al día (kWh/m²/día).\n\n'
            '4,5 kWh/m² al día equivale a recibir el sol "a tope" durante unas 4,5 horas cada día. '
            'A eso se le llama horas sol pico.',
        contentEn:
            '• kW (kilowatt) measures power: how strong the sun or an appliance is at a given '
            'moment. It is like the speed of a car.\n\n'
            '• kWh (kilowatt-hour) measures energy: how much accumulates over time. It is like the '
            'kilometers traveled.\n\n'
            'The electricity bill is measured in kWh, and the solar radiation of a place is '
            'expressed in kWh per square meter per day (kWh/m²/day).\n\n'
            '4.5 kWh/m² per day is equivalent to receiving the sun "at full strength" for about '
            '4.5 hours every day. That is called peak sun hours.',
      ),
      _LessonSpec(
        number: 3,
        id: 'l2c',
        type: 'lectura',
        titleEs: 'El recurso solar en Colombia',
        titleEn: 'The solar resource in Colombia',
        contentEs:
            '• Promedio nacional: cerca de 4,5 kWh/m² al día, superior al promedio mundial de 3,9.\n\n'
            '• Poca variación durante el año: por estar cerca del ecuador, no hay estaciones que '
            'reduzcan la producción de forma marcada.\n\n'
            '• La Guajira y el Caribe: son las zonas que más radiación reciben. La Guajira presenta '
            'cerca de 6,0 kWh/m² al día.\n\n'
            '• Datos locales: los promedios regionales son una guía. La radiación real depende de '
            'la ciudad, la orientación del techo, la sombra y el clima del sitio.',
        contentEn:
            '• National average: about 4.5 kWh/m² per day, higher than the world average of 3.9.\n\n'
            '• Little variation throughout the year: because it is near the equator, there are no '
            'seasons that markedly reduce production.\n\n'
            '• La Guajira and the Caribbean: these are the areas that receive the most radiation. '
            'La Guajira has about 6.0 kWh/m² per day.\n\n'
            '• Local data: regional averages are a guide. Actual radiation depends on the city, '
            'roof orientation, shade and the local climate.',
      ),
      _LessonSpec(
        number: 4,
        id: 'l2d',
        type: 'lectura',
        titleEs: 'Cómo gastar menos electricidad en casa',
        titleEn: 'How to use less electricity at home',
        contentEs:
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
        contentEn:
            'The cheapest energy is the energy you do not consume. Reducing consumption first '
            'means that, if panels are installed later, fewer will be needed.\n\n'
            '• Refrigerator (about 30% of usage): keep it between 2 and 6 °C, away from the oven '
            'and washing machine, and open it as little as possible.\n'
            '• Efficiency label: classes A, B and C are low consumption; F and G are high consumption.\n'
            '• Television: LEDs use 25% less than LCDs and 40% less than plasma.\n'
            '• Phantom load: devices that are plugged in, even when off, use between 5% and 8%. '
            'Unplugging them can save about 10% per month.\n'
            '• Washing machine: use short cycles, cold water and full loads.\n'
            '• Schedules: use appliances during off-peak hours and avoid the peak between 6 p.m. '
            'and 8 p.m.\n'
            '• Natural light and LED: take advantage of daylight and use LED bulbs.',
      ),
      _LessonSpec(
        number: 5,
        id: 'l2v1',
        type: 'video',
        youtubeId: 'q5bMAz4NK0c',
        titleEs: 'Video: Paneles solares y ahorro',
        titleEn: 'Video: Solar panels and savings',
      ),
      _LessonSpec(
        number: 6,
        id: 'l2v2',
        type: 'video',
        youtubeId: 'jO8HBDaok5l',
        titleEs: 'Video: Energía solar en Colombia',
        titleEn: 'Video: Solar energy in Colombia',
      ),
      _LessonSpec(
        number: 7,
        id: 'l2v3',
        type: 'video',
        youtubeId: 'BbIUE5xr65Q',
        titleEs: 'Video: Cálculo de consumo',
        titleEn: 'Video: Calculating consumption',
      ),
    ],
  ),
  _LevelSpec(
    number: 3,
    id: 'nivel_3',
    titleEs: 'Nivel 3 - Avanzado',
    titleEn: 'Level 3 - Advanced',
    subtitleEs: 'Del efecto fotovoltaico al cálculo del consumo',
    subtitleEn: 'From the photovoltaic effect to calculating consumption',
    lessons: [
      _LessonSpec(
        number: 1,
        id: 'l3a',
        type: 'lectura',
        titleEs: 'Cálculo de kWh/mes',
        titleEn: 'Calculating kWh/month',
        contentEs:
            'kWh/mes = (potencia (W) × horas al día × días a la semana × cantidad × 4,345) / 1000\n\n'
            '1. Busca la potencia (W) en la etiqueta del aparato.\n'
            '2. Anota cuánto lo usas: horas al día y días a la semana.\n'
            '3. Cuenta cuántos tienes iguales.\n'
            '4. Multiplica todo y luego por 4,345 (las semanas promedio de un mes).\n'
            '5. Divide entre 1000 para pasar de vatios a kilovatios y obtener kWh.\n\n'
            'Ejemplo: un televisor de 100 W, 5 horas al día, 7 días a la semana:\n'
            '(100 × 5 × 7 × 1 × 4,345) / 1000 ≈ 15,2 kWh al mes.\n\n'
            'Repite esto con cada aparato y suma los resultados.',
        contentEn:
            'kWh/month = (power (W) × hours per day × days per week × quantity × 4.345) / 1000\n\n'
            '1. Find the power (W) on the appliance label.\n'
            '2. Note how much you use it: hours per day and days per week.\n'
            '3. Count how many identical ones you have.\n'
            '4. Multiply everything and then by 4.345 (the average weeks in a month).\n'
            '5. Divide by 1000 to convert watts to kilowatts and get kWh.\n\n'
            'Example: a 100 W television, 5 hours a day, 7 days a week:\n'
            '(100 × 5 × 7 × 1 × 4.345) / 1000 ≈ 15.2 kWh per month.\n\n'
            'Repeat this for each appliance and add up the results.',
      ),
      _LessonSpec(
        number: 2,
        id: 'l3b',
        type: 'lectura',
        titleEs: 'Dimensionar paneles solares',
        titleEn: 'Sizing solar panels',
        contentEs:
            'Con el total mensual puedes estimar cuántos kW de paneles necesitas.\n\n'
            'kW de paneles ≈ kWh al día ÷ (horas sol pico × 0,8)\n\n'
            'Por ejemplo, 150 kWh/mes son 5 kWh/día; 5 ÷ 4,5 ÷ 0,8 ≈ 1,4 kW.\n\n'
            'Es solo un orden de magnitud, porque el 0,8 representa pérdidas típicas y varía según '
            'cada instalación.',
        contentEn:
            'With the monthly total you can estimate how many kW of panels you need.\n\n'
            'kW of panels ≈ kWh per day ÷ (peak sun hours × 0.8)\n\n'
            'For example, 150 kWh/month is 5 kWh/day; 5 ÷ 4.5 ÷ 0.8 ≈ 1.4 kW.\n\n'
            'It is only an order of magnitude, because 0.8 represents typical losses and varies '
            'with each installation.',
      ),
      _LessonSpec(
        number: 3,
        id: 'l3c',
        type: 'lectura',
        titleEs: 'Radiación y horas sol pico',
        titleEn: 'Radiation and peak sun hours',
        contentEs:
            '• Radiación en Colombia: promedio de 4,5 kWh/m² al día. En La Guajira llega a cerca de 6,0.\n'
            '• Promedio mundial: unos 3,9 kWh/m² al día.\n'
            '• Unidad: la radiación diaria se expresa en kWh/m² por día. Si ves kW/m², es potencia, '
            'no energía diaria.\n'
            '• Horas sol pico: 4,5 kWh/m² al día equivale a unas 4,5 horas de sol "a tope" cada día.',
        contentEn:
            '• Radiation in Colombia: average of 4.5 kWh/m² per day. In La Guajira it reaches '
            'about 6.0.\n'
            '• World average: about 3.9 kWh/m² per day.\n'
            '• Unit: daily radiation is expressed in kWh/m² per day. If you see kW/m², that is '
            'power, not daily energy.\n'
            '• Peak sun hours: 4.5 kWh/m² per day is equivalent to about 4.5 hours of "full" sun '
            'each day.',
      ),
      _LessonSpec(
        number: 4,
        id: 'l3v1',
        type: 'video',
        youtubeId: 'L3tPufMH071',
        titleEs: 'Video: Efecto fotovoltaico',
        titleEn: 'Video: Photovoltaic effect',
      ),
      _LessonSpec(
        number: 5,
        id: 'l3v2',
        type: 'video',
        youtubeId: 'nca2Lt-BS3U',
        titleEs: 'Video: Cálculo avanzado de consumo',
        titleEn: 'Video: Advanced consumption calculation',
      ),
    ],
  ),
];
