---
title: Un Nuevo SDK de Transbank
subtitle: Implementar Webpay en PHP acaba de volverse extremadamente fácil
draft: false
date: 2020-01-07T11:18:48-03:00
categories: ["Tech"]
tags: ["OSS", "Transbank", "PHP"]
---

Si has usado el SDK de Transbank para PHP quizás entiendas la frustación que me motivó a escribir un nuevo SDK no oficial. Hace mucho tiempo que tenía este proyecto en mente y decidí que el mundo no podía comenzar otra década sin un nuevo SDK de Transbank. 

<!--more-->

Así que, sin más, les presento a...

[¡BETTER TRANSBANK SDK!](https://github.com/better-transbank/sdk)

{{< figure src="https://media.giphy.com/media/MOWPkhRAUbR7i/giphy-downsized.gif" title="¡Wohooo por fin!" >}}

Este proyecto tiene como objetivo proveer un SDK estable, fácil de usar y seguro, con las mejores prácticas de desarrollo y POO y con un sistema de integración continua sólido y que asegure la calidad del software a cada momento.

Quisiera contarles las motivaciones, desarrollo y filosofía del proyecto, además de lanzar unas pequeñas ideas que tengo para este proyecto en el futuro.

## Hacia un mejor cliente
He tenido la suerte de haber desarrollado variadas integraciones de todo tipo. He construido clientes para muchos servicios de terceros y apis públicas, tanto RPC, REST y SOAP (siempre con PHP). Con el tiempo, esta experiencia me ha llevado a madurar ideas sobre lo que constituye un buen cliente.

Estas son las ideas que he llegado a abrazar como reglas a la hora de construir un cliente **ADECUADO**.

1. Un buen cliente debe ser **A**bstracto
2. Un buen cliente debe ser **D**ecorable
3. Un buen cliente debe ser **E**xtensible
4. Un buen cliente debe ser **C**acheable
5. Un buen cliente debe ser **U**niforme
6. Un buen cliente debe ser **A**tractivo 
7. Un buen cliente debe ser **D**ebuggeable
8. Un buen cliente debe ser **O**bvio

Muchas de estas reglas simplemente no se cumplen en el SDK original. Primero, carece de abstracciones apropiadas (casi no hay encapsulamiento) y el hecho que estamos usando SOAP se desparrama por toda la librería (cuando en realidad el protocolo es un mero detalle de implementación). No es decorable, debido a que no usa interfaces. No es extensible a un nivel de comunicación vía eventos. Carece de uniformidad debido a que no se atreve a reparar las inconsistencias del web service al que abstrae. No es para nada atrativo de usar y el código no usa los estándares de estilo de PHP FIG. Es debuggeable, pero solo al nivel del cliente de SOAP. Y no es muy obvio de usar, debido a que no nombra sus clases y variables de una forma clara.

Si eres un buen lector te habrás dado cuenta que en ningún lugar mencioné funcionamiento. Esto, porque que algo funcione es lo mínimo que se espera de una pieza de software. El SDK oficial funciona, ¡y bastante bien! Pero cuando hablamos de software no basta con que funcione: el usuario es el foco principal. El usuario debe disfrutar la herramienta que le estamos entregando. No sirve mucho lograr que algo funcione si el hacerlo funcionar se torna en una lucha. Y bueno, tú, querido amigo desarrollador, eres el usuario de este SDK. Espero que disfrutes el usarlo tanto como yo disfruté el desarrollarlo.

Por todas estas razones, decidí tomar el papel y comenzar desde cero. Esto, porque a pesar de que ha habido intentos de mejorar el SDK (véase [`freshwork/transbank`](https://github.com/freshworkstudio/transbank-web-services)), siempre quedan constreñidos por la implementación interna del cliente SOAP y terminan casi replicando el original, sin aportar más que un par de nuevas funcionalidades.

Asi que, me puse manos a la obra.

## La Api Inicial

Decidí partir implementando Webpay para lograr un MVP. Haciendo a un lado todos los detalles de implementación, como SOAP, construcción de XML, firmado de XML y otras cosas, el webservice de transbank nos expone tres métodos para nuestro uso, que modelé en una interfaz.

```php
<?php

interface WebpayClient
{
    public function startTransaction(Transaction $transaction): StartTransactionResponse;

    public function getTransactionResult(string $transactionToken): TransactionResult;
  
    public function confirmTransaction(string $transactionToken): void;
}
```

A diferencia de este ejemplo, en la librería las interfaces están documentadas, con el propósito de ayudar lo máximo al desarrollador si es que éste cuenta con buenas herramientas de autocompletar.

Algo importante que debemos notar es que allí donde hay más de dos parámetros en un método, agrupamos esos parámetros en clases tipo DTO (ojalá inmutables) y les damos significado por medio de nombrarlas. Las respuestas complejas también son clases, con una api clara y definida.

La clase `Transaction` es la principal aquí. Intenté modelarla tal y como el wsdl de transbank muestra, manteniendo los parámetros requeridos, opcionales y las estructuras. Parte de la api permite agregar detalles de pago, cambiar el tipo de transacción y provee un static factory para escritura de código fluída.

```php
<?php

use BetterTransbank\SDK\Webpay\Message\Transaction;

 // Creamos la transacción con las url
$transaction = Transaction::create('http://redirect.url', 'http://final.url')
    ->makeTypeMall('OrdenPrincipal', '2152152111') // Covertimos la transacción en tipo Mall
    ->withAddedDetails('Orden1234', 10000, '3532362362') // Añadimos detalles
    ->withAddedDetails('Orden1441', 15000, '5352523'); // Añadimos más detalles
```

`Transaction` es un mensaje, y es buena práctica que las clases que modelan mensajes en POO sean implementadas de forma inmutable (es decir, que los cambios de estado no modifican la referencia original).

### Firmando los XML
Pasar las clases a un arreglo que luego es convertido a XML es trivial para el cliente de SOAP de PHP. Lo que no es para nada trivial es firmar el XML usando el estándar WSSE (que es lo que usa, con un poco de variaciones, los servicios de Transbank). 

Tenía dos opciones: usar unas clases arcanas, complejas y viejas desarrolladas por un tal Robert Richards (que es lo que usa el SDK original) o implementar mi propio mecanismo de firma desde cero.

Encontré lo segundo más beneficioso y desafiante, debido a que podría aprender cómo funciona el estándar (créanme, ahora soy un experto en firmar XML con WSSE). Asi que pasé unos buenos tres días solo haciendo pruebas de concepto, leyendo los estándares y la documentación y buscando implementaciones en PHP y otros lenguajes.

Estuve un día entero parado porque Transbank me decía que la firma de mi XML no era válida, hasta que logré dar con el problema: yo estaba firmado el nodo `Body` del XML, pero lo que se firma es el nodo canonizado llamado `SignedInfo`, que a su vez contiene un `Digest` sha1 del nodo canonizado del `Body`.

El proceso, paso por paso por si te interesa, es el siguiente:

1. Marcar el nodo `SOAP-ENV:Body` con un atributo `wsu:Id`. Yo use un uuid, tal como el SDK original.
2. Añadir el nodo `SOAP-ENV:Header` antes que el nodo del body.
3. Añadir el  `wsse:Security` dentro del header, y el `ds:Signature` dentro de éste
4. Dentro de `ds:Signature`, se añaden varios nodos dentro de un `ds:SignedInfo` que contiene `ds:Reference`. El reference referencia este uuid antes creado, y además calcula un `sha1` de la canonicalización del nodo que contiene el `wsu:Id`. El sha1 debe estar encodeado en base64 y no en hexadecimal como suele estar.
5. Luego, se toma todo este nodo `ds:SignedInfo` recién creado, se canoniza y se firma con la llave privada usando `openssl_sign`. El algoritmo es sha1 también. La firma se encodea en base64 y se coloca en el nodo `ds:SignatureValue`, dentro de `ds:Signature`
6. Luego, se crea un nodo `ds:KeyInfo` dentro de `ds:Signature` que contiene la información del certificado público, para que Transbank pueda encontrarlo en su base de datos y validar si el mensaje realmente proviene de nosotros.

Un xml ya firmado, luce de esta forma:

```xml
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                   xmlns:ns1="http://service.wswebpay.webpay.transbank.com/">
    <SOAP-ENV:Header>
        <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                       SOAP-ENV:mustUnderstand="1">
            <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
                <ds:SignedInfo>
                    <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                    <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
                    <ds:Reference URI="#pfxbaea1ea6-963f-4b71-aaae-e64d8605def3">
                        <ds:Transforms>s
                            <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                        </ds:Transforms>
                        <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
                        <ds:DigestValue>N034GgBG1Q9Gx/OH1iq9ala4M8k=</ds:DigestValue>
                    </ds:Reference>
                </ds:SignedInfo>
                <ds:SignatureValue>
                    DVXWn1IpviwmaujYb3q97SOV3l/5BDrA9sTFjg51x5tSjrUlmelIHC5sx7Sjw/R8qHb2i0BL642uW2i7cZMUgmEUGemQQNI3e4W1QVXJT6iQlSgi3/kGO8OTSaiAraG7EFHeKLyf2m2HY/Nv2n9zzYIM2MPKtytQ7rumpp3tXLc9bvo5XZSCobCsNJzj01DxXiZy3+uxCB2G7a8PPvUNbl99Fa7XoRk2PjLKcpx/WBNQLlHZ6e5pho1EFRfGS0svrPUoE9mxKg/FdDuLc8/p22GOFvXBDAviUlxR9IwqoIgM2BCXTC3PAgmRFaDck9EfUpcwqnIubLjNJj1SEtCFeA==
                </ds:SignatureValue>
                <ds:KeyInfo>
                    <wsse:SecurityTokenReference>
                        <ds:X509Data>
                            <ds:X509IssuerSerial>
                                <ds:X509IssuerName>
                                    C=cl,ST=stgo,L=stgo,O=tbk,OU=ccrr,CN=597020000540,emailAddress=ccrr@gmail.com
                                </ds:X509IssuerName>
                                <ds:X509SerialNumber>16407850704409370121</ds:X509SerialNumber>
                            </ds:X509IssuerSerial>
                        </ds:X509Data>
                    </wsse:SecurityTokenReference>
                </ds:KeyInfo>
            </ds:Signature>
        </wsse:Security>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
                   wsu:Id="pfxbaea1ea6-963f-4b71-aaae-e64d8605def3">
        <ns1:initTransaction>
            <wsInitTransactionInput>
                <wSTransactionType>TR_NORMAL_WS</wSTransactionType>
                <returnURL>http://localhost:8000/return</returnURL>
                <finalURL>http://localhost:8000/final</finalURL>
                <transactionDetails>
                    <sharesAmount>0</sharesAmount>
                    <sharesNumber>0</sharesNumber>
                    <amount>10000</amount>
                    <commerceCode>597020000540</commerceCode>
                    <buyOrder>12345</buyOrder>
                </transactionDetails>
            </wsInitTransactionInput>
        </ns1:initTransaction>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
```

Fue bastante gratificante intelectualmente aprender a realizar el proceso. Incluso aprendí que Transbank no implementa el estándar al 100%, debido a que la información del certificado público suele enviarse en un header `wsse:BinarySecurityToken` y no en un `ds:KeyInfo`. Si Transbank implementa el estándar en sus herramientas de desarrollo, debería funcionar de esa forma también. Lo probaré en algún momento.

{{< figure src="https://media.giphy.com/media/26tPnAAJxXTvpLwJy/giphy-downsized.gif" title="Soy un nerd consumado..." >}}

## Utilidades y extensibilidad

Luego de que el desarollo duro estuvo terminado, lo único que faltaba era desarrollar un par de utilidades más y hacerlo un poco más extensible.

Por ejemplo, para hacer las redirecciones especiales que requiere Webpay (formularios HTTP enviados programáticamente por medio de javascript), he desarrollado un par de clases utilitarias que permiten realizar este proceso de forma extremandamente sencilla. Debo, sin emabargo, dar crédito al SDK de Freshworks Studio por ser los primeros en implementar esta idea.

```php
<?php

$response = $webpay->startTransaction($transaction);

PaymentForm::prepare($response)->send(); // Renderiza el formulario de pago y envía headers HTTP como respuesta
```

Además, puedes conectarte a cualquier parte del proceso de pago usando una implementación de [`psr/event-dispatcher`](https://www.php-fig.org/psr/psr-14/) y el decorador especial del cliente de Webpay.

```php
<?php

use BetterTransbank\SDK\Webpay\SoapWebpayClient;
use BetterTransbank\SDK\Webpay\Psr14\Psr14WebpayClient;

$webpay = WebpaySoapClient::fromCredentials($creds);
$webpay = new Psr14WebpayClient($webpay, $dispatcher);

$webpay->startTransaction($transaction); // Ahora este cliente dispara eventos
```

Por último, si necesitas ver información para debuggear requests, puedes usar el cliente SOAP especial
con capacidades de logger. Necesitarás una implementación que use la interfaz recomendada por FIG `LoggerInterface`, definida en [`psr/log`](https://github.com/php-fig/log). Casi todos los loggers para PHP usan esa interfaz hoy en día.

```php
<?php

use BetterTransbank\SDK\Soap\LoggerTransbankSoapClient;
use BetterTransbank\SDK\Webpay\SoapWebpayClient;
use BetterTransbank\SDK\Webpay\WebpayCredentials;

$creds = WebpayCredentials::normalStaging();
$logger = new SomeCOmpatibleLogger();
$client = new LoggerTransbankSoapClient($creds, $logger);
$webpay = new SoapWebpayClient($client); // Nota como NO creamos automáticamente desde credenciales ahora
```

Todas estas son utilidades que permiten una mejor experiencia de desarrollo y una más fácil integración y modificación de la lógica del SDK.

## Lo que se viene
Esta librería **no se encuentra lista para su uso en producción**. Es por eso que está sólo en versión `0.1.0` (al tiempo de la escritura de este artículo). Sin embargo, puedes probarla en desarrollo sin problemas. Sólo tengo implementado Webpay Normal y Mall.

De todas maneras, tengo un *roadmap* bastante claro para llegar a `1.0.0`, que será la versión *production-ready* de esta librería y que no debería pasar de fines de este mes. Principalmente, son tres grandes cosas las que faltan. 

La primera y una de las cossas más importantes que se necesita es validar la firma de las respuestas de Transbank. Considero esto un riesgo de seguridad demasiado alto como para usar la librería en producción. Una vez esa lógica esté implementada, lo que sigue es corregir los errores de análisis estático encontrados por psalm. Luego de eso, es vital incrementar el coverage de pruebas unitarias/funcionales a un 90%. Una vez que todo esto esté listo, recién entonces *taggearé* `1.0.0` (podría haber BC breaks en medio, ya que es un release *major*).

Cuando `1.0.0` vea la luz, me enfocaré en `1.1` que agregará OnePay. Quizá `1.2` agregue Webpay Nullify, pero de ahí en adelante el roadmap no lo tengo tan claro.

Cuando `1.0.0` esté completo, en paralelo al resto desarrollaré diferentes integraciones con distintos frameworks y plataformas. Symfony y Laravel serán los primeros, y luego de eso vendrá algún plugin de Wordpress, Magento y/o Prestashop.

El gran proyecto que tengo en mente para culminar todo esto es el desarrollo de un microservicio que permita implementar Webpay Plus Normal en tiempo récord, con notificaciones de pago al frontend via SSE (La api browser de EventSource).

## Sé parte

Como ves, tengo mucho trabajo que hacer y si quieres ayudarme estaría más que agradecido. Busco personas que prueben el SDK en su versión actual, que ayuden a desarrollar lo que falta, que mejoren la documentación o que me motiven comprándome un cafecito o una cervecita. ¡Todo sirve!

Si quieres ser el primero en enterarte de todo lo que se viene, no dudes en [poner una estrella en el repositorio](https://github.com/better-transbank/sdk).

¡Gracias por leer todo hasta acá! ¡Déjame un comentario para saber si te gustó!