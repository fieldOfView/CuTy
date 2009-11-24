CuTy
================================================================

CuTy is a tiny, dedicated viewer for (single node, JPEG encoded, 
cubic) QTVR .mov files based for Flash Player 10 and newer.


License
-------

CuTy and its sourcecode is released under the MIT License, see
LICENSE.txt.


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
path to the Quicktime VR file setting the FlashParam to 
"mov=cubicvr.swf".

For more information about how to use CuTy.swf, see the CuTy
website:
http://opensource.ivrpa.org/cuty
 

