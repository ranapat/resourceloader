package org.ranapat.resourceloader {
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.system.ApplicationDomain;
	import org.ranapat.resourceloader.libs.getDefinitionNames;

	final public class ResourceLoaderHelper {
		public static function getDispalyObject(target:Object):DisplayObject {
			var result:DisplayObject;
			try {
				result = (target.loader as Loader).content;
			} catch (e:Error) {
				//
			}
			return result;
		}

		public static function getClassDefinition(linkName:String, applicationDomain:ApplicationDomain):Class {
			var result:Class;
			try {
				result = applicationDomain.getDefinition(linkName) as Class;
			} catch (e:Error) {
				//
			}
			return result;
		}

		public static function getAllClassDefinitions(target:Object):Vector.<String> {
			var result:Vector.<String>;
			try {
				result = getDefinitionNames(target);

				var length:uint = result.length;
				for (var i:uint = 0; i < length; ++i) {
					result[i] = result[i].replace("::", ".");
				}
			} catch (e:Error) {

			}
			return result;
		}

		public static function keyExistsInArray(key:Object, array:Array = null):Boolean {
			return array && array.indexOf(key) != -1;
		}
		
		public static function stringKeyExistsInVector(key:String, array:Vector.<String> = null):Boolean {
			return array && array.indexOf(key) != -1;
		}
		
		public function ResourceLoaderHelper() {
			Tools.ensureAbstractClass(this, ResourceLoaderHelper);
		}

	}
}
