Codea Runtime Library (BETA)
============================

This is the Codea Runtime Library. It provides all the Lua bindings, graphics, sound and runtime engine for Codea on iPad. Using this library you can create standalone apps from a [Codea](http://twolivesleft.com/Codea/) project.

Esta en la librería runtime de Codea. En ella se encuentran los enlaces Lua, gráficos, sonido y motores runtime para Codea en iPad. Usando esta librería puede crear aplicaciones desde un poryecto Codea.

This version is a BETA. Please report any issues to us on the issue tracker on github. The underlying library is release-worthy, but the related scripts could have issues.

Esta es la version Beta, por favor avíse cualquier error y problema encontrado en el buscador de errores de Github. La librería matriz esta correcta pero los scripts pueden contener errores.

Versions
-------
Versiones

La superior es la mas reciente.

The topmost is the current version.

- **1.4.3** Current Codea Version - Mostly bug fixes
- **1.4.2** Current Codea Beta version
- **1.4.1** Current Codea version
- **1.3.6** Release BETA Version

License
Licencia
-------

The Codea Runtime Library is Copyright 2012 [Two Lives Left](http://www.twolivesleft.com) and is licensed under the Apache License v2.0.

La libreria runtime de Codea es una marca registrada de Two Lives Left desde el 2012 y tiene una licancia Apalache versión 2.0

Requirements
Requisitos
------------

The Codea Runtime Library requires Mac OS X and the iOS 5.0 Developer Tools. An iOS Developer License is required to build for devices and distribute on the Apple App Store.

La librería runtime de Codea necesita las herramientas de desarrollador  Mac OS X y el iOS 5.2. Es necesaria una licencia de desarrollador iOS para crear aplicaciones y distribuirlas en la tienda de Apple

Setup
Configuración
-----

Extracting your project's codea folder from the iPad can be done using [iExplorer](http://www.macroplant.com/iexplorer/)

Puedes extraer la carpeta de tu proyecto Codea en el Ipad usando iExplorer

1. Run the make_project.sh script from a Terminal session. It takes a parameter which is the name of the app.
   + eg, `./make_project.sh Test` will create a folder called **Test** with a CodeaTemplate.xcodeproj file inside it and targets of the same name set up 
2. Open the CodeaTemplate.xcodeproj project in Xcode.
3. Delete the existing the Project.codea file from the Classes group and select Move To Trash
4. Rename your codea project Project.codea
5. Drag and drop your project into the Xcode project
6. Check the "Copy items into destination folder's group (if needed)"
7. Select "Create folder references for any added folders" and make sure your app's  target is selected. Click Finish
8. Setup the bundle id and Icon for your project as per usual

1.	Ejecutar el script make_project.sh desde la consola.
•	eg, ./make_project.sh Test will create a folder called Test with a CodeaTemplate.xcodeproj file inside it and targets of the same name set up
2.	Abrir en Xcode CodeaTemplate.xcodeproj
3.	Borrar el Project.codea existente de las Clases de grupo y seleccionar Eliminar
4.	Renombrar el proyecto Project.codea
5.	Arrastre y suelte su proyecto en el proyecto Xcode
6.	Revise la opción “Copiar elementos la carpeta de grupo destino (De ser necesario)”
7.	Seleccione “Crear carpeta de referencia para cualquier carpeta” y asegúrese de que la aplicación  que creó está seleccionada. Presione Terminar
8.	Configura el id y el ícono de su proyecto

Issues
Errores
------

Please report any issue on the github issue tracker, and/or on the [Codea forums](http://www.twolivesleft.com/Codea/Talk).

Por favor reporte cualquier inconveniente en el buscador de errores de GitHub y/o en los foros de Codea

Open Source Libraries
Librerías de software libre
---------------------

The Codea Runtime Library uses the following open source libraries with gratitude to the developers:

La librería runtime de Codea usa las siguientes librerías de software libre, con permiso de sus desarrolladores:

+ [Lua 5.1](http://www.lua.org/)
+ [Box2D](http://box2d.org/)
+ [ASIHttpRequest](http://allseeing-i.com/ASIHTTPRequest/)
+ [libb64](http://libb64.sourceforge.net/)
+ [CCTexture2D](http://www.cocos2d-iphone.org/) (from Cocos2D)
+ [GLM](http://glm.g-truc.net/)
+ [ObjectAL](http://kstenerud.github.com/ObjectAL-for-iPhone/)
+ [SFXR](http://code.google.com/p/sfxr/)
+ [UIDevice-Hardware](https://github.com/erica/uidevice-extension)

In addition, the Codea API was inspired by [Processing](http://processing.org/).

El entorno de desarrollo de Codea esta inspirado en Processing.

Sprite Pack Attribution
-----------------------
+ "Planet Cute" art by Daniel Cook ([Lostgarden.com](http://lostgarden.com))
+ "Small World" art by Daniel Cook ([Lostgarden.com](http://lostgarden.com))
+ "SpaceCute" art by Daniel Cook ([Lostgarden.com](http://lostgarden.com))
+ "Tyrian Remastered" art by Daniel Cook ([Lostgarden.com](http://lostgarden.com))
+ "Cargo Bot" art by Simeon ([Two Lives Left](http://twolivesleft.com))

Copyright and Trademark Guidelines

Derechos de Autor y permisos de marca
----------------------------------

Guidelines for app developers using the Codea Runtime Library to produce apps for distribution.

Regulaciones para los desarrolladores que usen la librería runtime de Codea para desarrollar y distribuir aplicaciones.

**Authorized Use of Two Lives Left Trademarks**

**Uso autorizado de la marca Two Lives Left**

+ *Attribution:* You may use the Codea trademark when attributing Codea in your application, for example
  + You may include the "Made with Codea™" graphic in your application
  + You may describe your application as "Made with Codea" or "Made with the Codea Runtime Library" in your application's marketing materials
  
+ *Atribuciones*: puede usar la marca codea cuando coloque su nombre en la aplicación, por ejemplo
   + Puede incluir la imagen "Made with Codea™" en su aplicación
   + Puede describir su aplicación usando “Made with Codea” o “Made with Codea Runtime Library” en la campaña de mercadeo.

**Unauthorized Use of Two Lives Left Trademarks**

**Uso no autorizado de la marca Two Lives Left**

+ *Company, Product, or Service Name:* You may not use or register Codea, Two Lives Left, or any other Two Lives Left-owned trademark as part of a company name, product name, trade name or service name. This includes Two Lives Left-owned graphic symbols, logos and icons.
+ *Endorsement:* You may not use Codea, Two Lives Left, or any other Two Lives Left-owned tradmarks in a manner that would imply Two Lives Left's endorsement of a third party product or service.

+ *Compañía, producto o nombre de servicio:* no usará y registrará el nombre de Codea, Two Lives Left u otro nombre de la marca Two Lives Left como para del nombre de una compañía, producto, campaña de mercadeo o servicio. Esto también aplica a los gráficos, símblos, logos e íconos.
+ *Aprobación:* no usará el nombre de Codea, Two Lives Left u otro nombre de la marca Two Lives Left de forma que ésta se viera como responsable de un producto o servicio realizado por terceros.

**Marketing Graphics for Use in Your Products**

**Artes gráficos para usar en los proyectos**

+ You may use the following graphical elements in your products.

+ Puede usar los elementos gráficos mostrados abajo en sus productos.
  + [Made with Codea (White)](http://twolivesleft.com/Codea/MadeWithCodea-White.png)
  + [Made with Codea (Black)](http://twolivesleft.com/Codea/MadeWithCodea-Black.png)
