CuTy
================================================================

CuTy is a tiny, dedicated viewer for (single node, JPEG encoded, 
cubic) QTVR .mov files based for Flash Player 10 and newer. Its 
functionality is deliberately kept minimal.

CuTy was originally written by Aldo Hoeben 
(aldo@fieldofview.com) as a means to easily display uploaded 
QTVR files. It was first used publically at http://sziget360.com
and later at http://ivrpa.org and its subsites.


License
-------

This software is licensed under the Creative Commons Attribution
version 3.0 or later:
http://creativecommons.org/licenses/by/3.0/

In a nutshell, this means you are free to use the software and 
its source code in your projects. If you use (parts of) the 
source code in another software project, you are required to 
add attribution to the author. I encourage you to share the 
your source code in a similar fashion, but it is not a 
requirement.


How to build
------------

To build the CuTy.swf file, you need the open source Flex SDK, 
version 3.2 or newer, from Adobe:
http://opensource.adobe.com/wiki/display/flexsdk/Flex+SDK

To compile CuTy.swf, use the following commandline options:
mxmlc -target-player=10.0.0 -use-network=false CuTy.as


How to use
----------

A quick way to test CuTy.swf with your quicktime movie is to 
rename the swf file to match the name of the mov file, eg:
if your Quicktime VR file is called "cubicvr.mov", make a copy
of CuTy.swf named "cubicvr.swf" in the same folder as the 
Quicktime file. You can now open the cubicvr.swf in the 
Flash 10 standalone viewer provided with the open source Flex
SDK, or you can drop the swf file in your browser.

When included in an HTML file you may use the same technique
or you can keep the name of the CuTy.swf as is and supply the 
path to the Quicktime VR file setting the FlashVars to 
"mov=cubicvr.swf".

The fullscreen functionality of the viewer is only available
if the parent HTML specifically allows fullscreen display. 

For more information about how to use CuTy.swf, see:
http://fieldofview.com/projects/cuty
 

