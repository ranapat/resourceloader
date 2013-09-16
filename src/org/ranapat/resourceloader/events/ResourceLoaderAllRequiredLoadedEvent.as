package org.ranapat.resourceloader.events {
	import flash.events.Event;
	
	public class ResourceLoaderAllRequiredLoadedEvent extends Event {
		public static const TYPE:String = "resourceLoaderAllRequiredLoaded";
		
		public var bundle:String;
		
		public function ResourceLoaderAllRequiredLoadedEvent(bundle:String) {
			super(ResourceLoaderAllRequiredLoadedEvent.TYPE);
			
			this.bundle = bundle;
		}
		
	}

}