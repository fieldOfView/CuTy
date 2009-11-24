package com.fieldofview.qtparser {
	import flash.events.*;
	import flash.utils.ByteArray;

	public class MovParser {
		public var allDone:Boolean = false;
		public var message:String;

		public var imageFrames:uint = 1;
		public var cameraParameters:Array = new Array();
		public var tileInfo:Array = new Array();
		public var metaData:Object = new Object();

		private var movContent:ByteArray;
		private var movOffset:uint = 0;

		public var eventDispatcher:EventDispatcher = new EventDispatcher();
		public static var ERROR:String = "error";
		public static var INFO:String = "info";

		private static var FIND_MOOV:uint = 0;
		private static var LOAD_MOOV:uint = 1;
		private static var LOAD_MDAT:uint = 2;
		private static var ALL_DONE:uint = 3;
		private var parseState:uint = FIND_MOOV;

		private var moovStart:uint;
		private var moovLength:uint;

		private var mdatStart:uint;
		private var mdatLength:uint;

		private var videTrak:QTAtom;
		private var videPreviewTrak:QTAtom;


		public function MovParser(__content:ByteArray):void {
			movContent = __content;
		}

		public function handleStream():Boolean {
			var success:Boolean;

			switch (parseState) {
				case FIND_MOOV:	// find 'moov' atom from file header
					var atom:Object = {type:"", start:0, length:0};

					while (movContent.length >= movOffset + 8) {
						movContent.position = movOffset;

						atom.start = movOffset;
						atom.length = movContent.readUnsignedInt();
						atom.type = movContent.readUTFBytes(4);

						//sendLog("Found atom: " + atom.type, INFO);

						movOffset += atom.length;
						if (atom.type == "moov") {
							break;
						}
					}

					if (atom.type != "moov") {
						// 'moov' atom not found 
						break;
					} 

					sendLog("Parsing Quicktime file...", INFO);

					// 'moov' found
					moovStart = atom.start + 8;
					moovLength = atom.length - 8;
					parseState++;

					// NB: don't 'break;'

				case LOAD_MOOV:	// wait until 'moov' atom has fully loaded
					if (movContent.length < moovStart + moovLength) {
						// 'moov' not yet complete
						break;
					}

					sendLog("Parsing 'moov' atom...", INFO);
					success = parseMoovAtom();

					if (!success) 
						return false;

					parseState++;
					// NB: don't 'break;'
				
				case LOAD_MDAT:	// wait until 'mdat' atom has fully loaded
					if (movContent.length < mdatStart + mdatLength) {
						// 'pdat' not yet complete
						break;
					} 

					sendLog("Parsing 'mdat' atom...", INFO);
					success = parseMdatAtom();

					if (success) {
						sendLog("Parsing 'trac' atom(s)...", INFO);
						success = parseTrakAtoms()
					}

					if (!success) 
						return false;

					parseState++;
					// NB: don't 'break;'

				case ALL_DONE:
					allDone = true;
			}

			return true;
		}

		private function parseMoovAtom():Boolean {
			var moov:QTAtom = new QTAtom(movContent, moovStart, moovLength);
			if (moov.getAtom("cmov").length != 0) {
				// found 'cmov' atom, which means the header is compressed
				sendLog("compressed headers are not supported.", ERROR);
				return false;
			}

			var traks:Array = moov.getAtoms("trak");
			if (traks.length == 0) {
				sendLog("no 'trak' atoms found.", ERROR);
				return false;
			}

			// inspect 'trak' atoms, finding video and preview tracks.
			for (var _trak_nr:uint = 0; _trak_nr < traks.length; _trak_nr++) {
				var trak:QTAtom = traks[_trak_nr];

				var hdlr:QTAtom = trak.getAtom("mdia").getAtom("hdlr");
				if (hdlr.length == 0) {
					sendLog("no 'hdlr' atom found in 'trac' " + (_trak_nr + 1).toString() + ".", ERROR);
					return false;
				}

				// 'hdlr' interesting bits: N1flags/N1type/N1sub
				hdlr.position = 4;
				if (hdlr.readUTFBytes(4) == "mhlr" && hdlr.readUTFBytes(4) == "pano") {
					// type = mhlr, sub = pano;

					var stbl:QTAtom = trak.getAtom("mdia").getAtom("minf").getAtom("stbl");
					var stco:QTAtom = stbl.getAtom("stco");
					if (stco.length == 0) {
						sendLog("no 'stco' atom found.", INFO);
						return false;
					}
					// 'stco' interesting bits: N1flags/N1num/N1offset
					stco.position = 8;
					mdatStart = stco.readUnsignedInt();

					var stsz:QTAtom = stbl.getAtom("stsz");
					if (stsz.length == 0) {
						sendLog("no 'stsz' atom found.", ERROR);
						return false;
					}

					// 'stsz' interesting bits: N1flags/N1size/N1num
					stsz.position = 4;
					mdatLength = stsz.readUnsignedInt();

					var codec:String = "";
					var imgt:QTAtom = trak.getAtom("tref").getAtom("imgt");

					if (imgt.length >= 4) {
						videTrak = traks[imgt.readUnsignedInt()-1];
					
						if (imgt.length >= 8) {
							videPreviewTrak = traks[imgt.readUnsignedInt()-1];
							
							codec = getVideCodec(videPreviewTrak);
							if (codec=="") {
								videPreviewTrak = null;
							} else if (codec!="jpeg") {
								videPreviewTrak = null;
								sendLog("Skipping non-jpeg preview track.", INFO);
							} else {
								sendLog("Preview track detected.", INFO);
							}
						}
					}

					if (!videTrak) {
						sendLog("no 'vide' track found.", ERROR);
						return false;
					}

					codec = getVideCodec(videTrak);
					if (codec=="") {
						videTrak = null;
						sendLog("no 'stsd' atom found.", ERROR);
						return false;
					} else if (codec!="jpeg") {
						videTrak = null;
						videPreviewTrak = null;
						sendLog("only jpeg compressed panoramas are supported.", ERROR);
						return false;
					}

					break;
				}
			}

			if (!videTrak) {
				sendLog("incomplete 'pano' track in 'moov' atom.", ERROR);
				return false;
			}

			var udta:QTAtom = moov.getAtom("udta");
			metaData.title = getUdtaString(udta.getAtom("©nam"));
			metaData.author = getUdtaString(udta.getAtom("©aut"));
			metaData.copyright = getUdtaString(udta.getAtom("©cpy"));

			// found required bits in 'moov' atom
			return true;
		}

		private function parseMdatAtom():Boolean {
			var i:uint;

			var mdat_data:ByteArray = new ByteArray();

			movContent.position = mdatStart;
			movContent.readBytes(mdat_data, 0, mdatLength);

			for (var mdat_offset:uint = 0; mdat_offset < mdat_data.length; mdat_offset++) {
				if (mdat_data.readUTFBytes(1) == "p") {
					if (mdat_data.readUTFBytes(3) != "dat") {
						// not pdat; rewind in case 'pdat' is following
						mdat_data.position -= 3;

					} else {
						// found 'pdat' atom;
						mdat_data.position -= 8;
						break;
					}
				} 
			}
			if (mdat_offset >= mdat_data.length) {
				sendLog("could not parse 'mdat' atom.", ERROR);
				return false;
			}

			var mdat:QTAtom = new QTAtom(mdat_data, mdat_data.position, mdat_data.length - mdat_data.position)
			var pdat:QTAtom = mdat.getAtom("pdat");
			if (pdat.length == 0) {
				sendLog("'pdat' atom not found.", ERROR);
				return false;
			}

			// 'pdat' interesting bits: N3/n2ver/N2ref/f9cam/N2imgsize/n2imgframes/N2hotsize/n2hotframes/N1flags/N1type
			pdat.position = 88; 
			if (pdat.readUTFBytes(4) != "cube") {
				sendLog("not a cubic panorama.", ERROR);
				return false;
			} 
			pdat.position = 68;
			imageFrames = pdat.readUnsignedShort()/4;
			if (imageFrames != pdat.readUnsignedShort()) {
				sendLog("non-square tiles are not supported.", ERROR);
				return false;
			}


			var cuvw:QTAtom = mdat.getAtom("cuvw");
			if (cuvw.length == 0) {
				sendLog("'cuvw' atom not found.", ERROR);
				return false;
			} 
			cuvw.position = 12;

			for (i = 0; i<9; i++) {
				cameraParameters[i] = cuvw.readFloat();
			}
			
			var cufa:QTAtom = mdat.getAtom("cufa");
			tileInfo = new Array();
			if (cufa.length > 0) {
				for (i = 0; i < (cufa.length-12)/32; i++) {
					cufa.position = 12 + i * 32;
					var tile:Object = {orientation: [], center: []}
					var j:uint;
					for (j = 0; j < 4; j++) {
						tile.orientation[j] = cufa.readFloat();
					}
					for (j = 0; j < 4; j++) {
						tile.center[j] = cufa.readFloat();
					}

					tileInfo.push(tile);
				}
			} else {
				// no 'cufa' atom; create default cube face data;
				tileInfo.push({orientation:[ 1  , 0  , 0  , 0  ], center:[0,0]})
				tileInfo.push({orientation:[ 0.5, 0  ,-0.5, 0  ], center:[0,0]})
				tileInfo.push({orientation:[ 0  , 0  , 1  , 0  ], center:[0,0]})
				tileInfo.push({orientation:[ 0.5, 0  , 0.5, 0  ], center:[0,0]})
				tileInfo.push({orientation:[ 0.5, 0.5, 0  , 0  ], center:[0,0]})
				tileInfo.push({orientation:[ 0.5,-0.5, 0  , 0  ], center:[0,0]})
			}

			if (tileInfo.length == 0) {
				sendLog("no tile data found.", ERROR);
				return false;
			}

			return true;
		}

		private function parseTrakAtoms():Boolean {
			for (var preview:Number = 0; preview <= 1; preview++) {
				var trak:QTAtom
				if(!preview) 
					trak = videTrak;
				else
					trak = videPreviewTrak;

				if(trak == null) {
					continue;
				}

				var stbl:QTAtom = trak.getAtom("mdia").getAtom("minf").getAtom("stbl");
				
				var stsz:QTAtom = stbl.getAtom("stsz");
				if (stsz.length == 0) {
					sendLog("'stsz' atom not found.", ERROR);
					return false;
				}
				var stco:QTAtom = stbl.getAtom("stco");
				if (stco.length == 0) {
					sendLog("'stco' atom not found", ERROR);
					return false;
				}
				var stsc:QTAtom = stbl.getAtom("stsc");
				if (stsc.length == 0) {
					sendLog("'stsc' atom not found.", ERROR);
					return false;
				}				

				stsz.position = 8;
				stco.position = 4;
				
				var stsz_num:uint = stsz.readUnsignedInt();
				var stco_num:uint = stco.readUnsignedInt();
				
				if ( stsz_num != tileInfo.length ) {
					sendLog("inconsistent number of tiles in 'trac' atom.", ERROR);
					return false;
				}
				if ( stco_num != stsz_num ) {
					sendLog("Reconstructing 'stco' atom...", INFO);
					
					stsc.position = 4;
					var stsc_num:uint = stsc.readUnsignedInt();
					
					var stco_data:ByteArray = new ByteArray();
					var stco_index:Number = 0;
					
					var c_next:uint = stsc.readUnsignedInt();
					for (var s2c:Number = 0; s2c < stsc_num; s2c++) {
						var c_first:uint = c_next;
						var c_num:uint = stsc.readUnsignedInt();
						var c_desc:uint = stsc.readUnsignedInt();
						if(s2c<stsc_num-1) 
							c_next = stsc.readUnsignedInt();
						else
							c_next = stco_num+1;
						
						for(var c:Number = c_first; c < c_next; c++) {
							var base:uint = stco.readUnsignedInt();
							var offset:uint = 0;
							
							for(var t:Number = 0; t < c_num; t++) {
								stco_data.writeUnsignedInt(base + offset);
								stco_index++;
								if (stco_index < stsz_num)
									offset += stsz.readUnsignedInt();
							}
						}
					}
					stco = new QTAtom(stco_data,0,stco_data.length);
					stco.position = 0;
					stsz.position = 12;	
				}

				for each (var tile:Object in tileInfo) {
					if(!preview) {
						tile.start = stco.readUnsignedInt();
						tile.length = stsz.readUnsignedInt();
					} else {
						tile.previewStart = stco.readUnsignedInt();
						tile.previewLength = stsz.readUnsignedInt();
					}
				}
			}


			videTrak = null;
			videPreviewTrak = null;

			return true;
		}

		private function getUdtaString(__atom:QTAtom):String {
			if(__atom.length == 0)
				return "";

			var length:Number = __atom.readUnsignedShort();
			__atom.position = 4;
			return __atom.readUTFBytes(length);
		}

		private function getVideCodec(__trak:QTAtom):String {
			var stsd:QTAtom = __trak.getAtom("mdia").getAtom("minf").getAtom("stbl").getAtom("stsd");

			if (stsd.length == 0) 
				return "";

			// 'stsd' interesting bits: N1flags/N2/N1codec
			stsd.position = 12;

			return stsd.readUTFBytes(4); 
		}

		private function sendLog(__message:String, __type:String):void {
			message = __message;
			this.eventDispatcher.dispatchEvent(new Event(__type));
		}
	}
}