---
title: Entendiendo Versionamiento Semántico
subtitle: O por qué 1.0 no significa que una librería es mala.
categories: ["Tech"]
tags: ["PHP", "Semver", "OOP", "Composer", "Dependency Management"]
draft: false
date: 2019-10-12T11:18:48-03:00
---
Hace poco estaba hablando con un colega y recomendándole una librería para ayudarle en un problema que estaba tratando de resolver. Mientras le hablaba de cómo funcionaba la librería, abrió el repositorio Github de la misma y vio el número de version (1.1.5) y me dijo “No es muy buena, está solo en versión 1”.

Lo miré con cara de confundido e inmediatamente me di cuenta que su entendimiento de versionamiento semántico era algo así como “Las buenas librerías son las que tienen un número de version alto”. La realidad es que ese no es el caso.

Versionamiento Semántico (SemVer por su traducción al inglés) es un estándar muy específico utilizado principalmente en el mundo de proyectos Open Source para versionado de un codebase. Puedes leer la explicación detallada del estándar [aquí][semver], pero lo resumiré en este post.

Sin embargo, antes debemos comprender un par de cosas para poder entender qué problemas trata de resolver el Versionamiento Semántico y cómo es que lo hace.

## Compartiendo librerías
Todos nosotros, cuando programamos, usamos librerías de terceros. A veces necesitamos esa librería para trabajar con archivos excel como stream de datos, o esa otra librería para hacer peticiones HTTP, o quizás otra para trabajar con fechas de mejor manera.

En los días de antaño, para incluir código de terceros en tu proyecto, tenías que descargar la librería y colocarla en tu código, lo cual era extremadamente ineficiente. Hoy en día, necesitamos movernos más rápido, y la venida de la agilidad en el desarrollo de software hizo necesaria la implementación de formas más eficientes de compartir/integrar código. He aquí el nacimiento de los gestores de dependencias, o gestores de paquetes.

Lo más probable es que tu lenguaje de programación tiene un gestor de dependencias que te ayuda a instalar estas librerías en tu proyecto de manera fácil. PHP tiene Composer, Node tiene Yarn o NPM, Java y Kotlin tienen Maven y Gradle, Rust tiene Cargo, Ruby tiene Gems, Go tiene Dep, Python tiene Pip, etcétera. Con estas herramientas, simplemente tenemos que especificar el nombre de la librería que queremos ¡y listo!

¡Genial! Hemos resuelto un problema. ¡Ahora podemos compartir código fácilmente! Pero, este problema creó unos cuantos otros. Necesito mencionarlos antes de que pueda explicar qué es el Versionamiento Semántico.

### Problema Uno: "¡Esto tiene un bug!"
Supongamos que, usando el gestor de dependencias, obtengo una librería de abstracción del sistema de archivos, que me permite usar diversos adaptadores para distintos sistemas de archivo. Y supongamos que luego de un rato de usarla en mi código, descubro que tiene un bug de algún tipo.

Dada esta situación, necesito dos cosas. Primero, notificar al autor de la librería sobre el bug encontrado; y segundo, esperar que él/ella lo solucione para que yo pueda incluir este fix en mi propio código.

Por supuesto, podría entrar al vendor y arreglar el bug yo mismo. Pero te darás cuenta que modificar código de terceros en tu proyecto no sólo es una pésima práctica, sino una pésima idea; sobretodo si planeas hacer algún tipo de CI/CD o si trabajas con otras personas. Mejor, que esa idea ni se te pase por la cabeza.

### Problema Dos: “¡Podría necesitar esta nueva funcionalidad!”
No sólo necesitamos bugfixes o mejoras de seguridad en nuestro código, sino también nuevas funcionalidades. Supongamos que la librería que estoy usando sacó un nuevo adaptador para conectarme a un sistema de archivos por FTP y decido probarla. Necesito ser capaz de recibir este cambio también en el código.

Por supuesto, podría ser que el autor de la librería diseñó esta nueva funcionalidad, pero yo no la estoy usando. De todas maneras, no hay problema añadiendo cosas mientras no modifiques lo que ya existe.

### Problema Tres: “¡No lo cambies por favor!”
Ahora, supongamos que el autor de esta librería hará un rediseño completo de la misma: cambiará interfaces y apis, movera/renombrará clases y quitará algunas cosas de las cuales dependíamos. Ahora el asunto se complica bastante para nosotros: si hay un método que tiene otro nombre o una clase que estabamos usando, si actualizamos la librería nuestro código se romperá. No queremos eso, hasta que no tengamos claro que sabemos como actualizar nuestro código para usar la nueva versión.

## ¡Versionamiento Semántico al Rescate!
Entonces, dados estos problemas, tenemos tres tipos de cambios en el software: **cambios que siempre quiero tener** (bugfixes y mejoras de seguridad), **cambios que sería bueno tener pero que son totalmente opcionales** (nuevas funcionalidades) y **cambios que definitivamente no quiero tener** (cambios de api, renombramiento de una clase, etćetera).

Es aquí donde SemVer brilla. Básicamente, lo que hace es indicar qué tipo de cambio se ha efectuado en un codebase mediante el uso de un sistema de tres números. Ej: 1.4.7

El número de más a la derecha se le conoce como **patch**, y se incrementa cada vez que hay un cambio en el código que arregla uno o varios bugs o implementa una o más mejoras de seguridad.

El número del medio se conoce como **minor**, y se incrementa en uno cada vez que a un release que contiene una nueva funcionalidad o mejora. Es importante que esta mejora no quite nada de lo que ya existe. Por ejemplo, puedes añadir métodos a una clase, pero no quitar un método o renombrar uno existente.

El número de más a la izquiera se conoce como **major**, y se incrementa en uno cada vez que hay un cambio que modifica lo que ya existe, efectivamente rompiendo el contrato de funcionamiento.

## Usando SemVer
Usando estos números, podemos inteligente y confiadamente recibir mejoras y arreglos de bugs en el código de terceros que usamos, asegurándonos que no recibimos nuevas versiones **major** que remperían nuestro código.

La teoría de SemVer dice que, por ejemplo, si estoy usando la versión 1.0.4 de cierta librería, y quiero actualizar a la 1.6.0, es perfectamente posible y no debo preocuparme al respecto ya que no se rompería nada. No así, si quiero pasar a la versión 2.0.0. Esto me está indicando que hay un cambio que podría romper mi código. Todos los gestores de dependencias cuentan con el operador ^, que solo permite cambios de versiones **minor** y **patch**, pero no **major**. Es una excelente práctica usarlos.

Lo que hace la mayoría de la gente es que usan muy mal SemVer: especifican una versión exacta, como 1.6.0, pero con ello se pierden todas las mejoras de seguridad y nuevas funcionalidades. En PHP, incluso, he visto a personas requiriendo versiones `dev-master`. No hagas eso nunca.

## Evaluando librerías de acuerdo a SemVer
¿Dónde nos deja esto? Podemos razonar que librerías que tienen un corto periodo de vida pero un número de versiones **major** grande (superior a 4 o 5), no son librerías maduras, sino librerías muy inestables y agresivas, que siempre están rompiendo su api. Por otro lado, librerías que llevan mucho tiempo en su versión **major** (1 o 2) son estables y confiables, debido a que han demostrado no cambiar mucho y ser conservadoras en cuanto a su política de cambios.

Nunca es bueno confiar en librerías muy agresivas. En PHP aprendimos la lección cuando ocurrió el problema de Guzzle. El tiempo que pasó de Guzzle 4 a Guzzle 6 fue tan corto, que como muchas librerías dependían de Guzzle 4, las que usaban Guzzle 6 no podían instalarse, causando problemas de dependencias bastante molestos en el ecosistema de PHP. Esto incluso motivó la creación de HTTPlug como abstracción sobre Guzzle, para evitar este tipo de problemas.

[semver]: https://semver.org/lang/es/