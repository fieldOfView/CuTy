package com.fieldofview.qtparser {
	import flash.utils.ByteArray;

	public class QTAtom extends ByteArray {

		private var atoms:Array;
		private var allDone:Boolean;

		public function QTAtom (__parent_data:ByteArray, __atom_start:uint, __atom_length:uint) {
			__parent_data.position = __atom_start;
			__parent_data.readBytes(this, 0, __atom_length);

			this.atoms = new Array();
		}

		public function getAtom (__type:String):QTAtom {
			var offset:uint = 0;

			var atomFound:Boolean = false;
			var atomStart:uint = 0;
			var atomLength:uint = 0;

			// check atoms array
			for each(var atom:Object in this.atoms) {
				if(atom.type == __type) {
					atomStart = atom.start;
					atomLength = atom.length;
					atomFound = true;
					break;
				}
				offset += atom.length;
			}

			if (!atomFound && !allDone) {
				// continue parsing atoms
				while (offset < this.length - 8) {	// if the remainder is less than 8 bytes long, it can't be a valid atom
					this.position = offset;

					atomStart = offset;
					atomLength = this.readUnsignedInt();
					var atomType:String = this.readUTFBytes(4);

					if(atomStart + atomLength <= this.length)
						this.atoms.push({type:atomType, start:atomStart, length:atomLength});

					if(atomType == __type) {
						atomFound = true;
						break;
					}

					offset += atomLength;
				}
				
				// are we done parsing this atom?
				if (offset >= this.length - 8)
					this.allDone = true;
			}

			if(atomFound) {
				return new QTAtom(this, atomStart + 8, atomLength - 8);
			} else {
				return new QTAtom(new ByteArray, 0, 0);
			}
		}

		public function getAtoms(__type:String):Array {
			var result:Array = [];

			// make sure the atom is fully parsed
			if(!allDone)
				getAtom("    ");

			for each(var atom:Object in this.atoms) {
				if(atom.type == __type && atom.length > 0) {
					result.push(new QTAtom(this, atom.start + 8, atom.length - 8))
				}
			}

			return result;
		}
	}
}