package org.ranapat.resourceloader.events {
	import flash.events.Event;
	
	public class ResourceLoaderClassLoadedEvent extends Event {
		public static const TYPE:String = "resourceLoaderClassLoaded";

		public var name:String;
		public var _class:Class;
		
		public function ResourceLoaderClassLoadedEvent(name:String, _class:Class) {
			super(ResourceLoaderClassLoadedEvent.TYPE);
			
			this.name = name;
			this._class = _class;
		}
		
	}

}