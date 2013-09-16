package org.ranapat.resourceloader {
	import flash.events.EventDispatcher;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import org.ranapat.resourceloader.events.ResourceLoaderClassLoadedEvent;

	final public class ResourceClasses extends EventDispatcher {
		private static var _allowInstance:Boolean;
		private static var _instance:ResourceClasses;
		
		public static function get instance():ResourceClasses {
			if (!ResourceClasses._instance) {
				ResourceClasses._allowInstance = true;
				ResourceClasses._instance = new ResourceClasses();
				ResourceClasses._allowInstance = false;
			}
			return ResourceClasses._instance;
		}
		
		public var pending:Dictionary ;
		public var cache:Dictionary;
		
		public function ResourceClasses() {
			if (ResourceClasses._allowInstance) {
				this.pending = new Dictionary();
				this.cache = new Dictionary();
			} else {
				throw new Error("Use ResourceClasses::instance instead.");
			}
		}

		public function addClass(name:String, _class:Class):String {
			if (_class) {
				if (this.cache[name] == undefined) {
					this.cache[name] = _class;

					if (this.pending[name]) {
						ResourceLoader.instance.dispatchEvent(new ResourceLoaderClassLoadedEvent(name, _class));

						this.pending[name] = null;
						delete this.pending[name];
					}
				}

				return name;
			} else {
				return null;
			}
		}

		public function addClassFromApplicationDomain(name:String, applicationDomain:ApplicationDomain):String {
			return this.addClass(name, ResourceLoaderHelper.getClassDefinition(name, applicationDomain));
		}

		public function addAllClassesFromApplicationDomain(applicationDomain:ApplicationDomain, target:Object = null):void {
			var names:Vector.<String> = ResourceLoaderHelper.getAllClassDefinitions(target);
			for each (var name:String in names) {
				this.addClassFromApplicationDomain(name, applicationDomain);
			}
		}

		public function getClass(name:String, registerForSignalIfNull:Boolean = true):Class {
			if (this.cache[name] != undefined) {
				return this.cache[name];
			} else if (registerForSignalIfNull) {
				this.pending[name] = 1;
			}

			return null;
		}
	}
}
