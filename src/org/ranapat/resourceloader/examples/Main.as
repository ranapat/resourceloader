package org.ranapat.resourceloader.examples {
	import com.greensock.TweenLite;
	import flash.display.Sprite;
	import flash.events.Event;
	import org.ranapat.resourceloader.events.ResourceLoaderAllRequiredLoadedEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderBundleCompleteEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderClassLoadedEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderCompleteEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderFailEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderProgressEvent;
	import org.ranapat.resourceloader.ResourceClasses;
	import org.ranapat.resourceloader.ResourceLoader;
	
	public class Main extends Sprite {
		private var loader:ResourceLoader;
		
		public function Main():void {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			this.loader = ResourceLoader.instance;
			this.loader.addEventListener(ResourceLoaderProgressEvent.TYPE, this.handleProgress);
			this.loader.addEventListener(ResourceLoaderFailEvent.TYPE, this.handleFail);
			this.loader.addEventListener(ResourceLoaderCompleteEvent.TYPE, this.handleComplete);
			this.loader.addEventListener(ResourceLoaderClassLoadedEvent.TYPE, this.handleClassLoaded);
			this.loader.addEventListener(ResourceLoaderBundleCompleteEvent.TYPE, this.handleBundleLoaded);
			this.loader.addEventListener(ResourceLoaderAllRequiredLoadedEvent.TYPE, this.handleAllRequiredLoaded);
			
			trace("try to get the class :: " + ResourceClasses.instance.getClass("example.package.SomeTestClassA"));
			
			trace("try to load asset :: " + this.loader.load("../assets/assetsA_.swf", 1, "b1", true));
			trace("try to load asset :: " + this.loader.load("../assets/assetsB.swf", 2, "b1"));
		}
		
		private function handleProgress(e:ResourceLoaderProgressEvent):void 
		{
			trace("progress.... " + e.uid + " .. " + e.progress + " .. " + e.bundle)
		}
		
		private function handleFail(e:ResourceLoaderFailEvent):void 
		{
			trace("fail.... " + e.uid + " .. " + e.reason)
		}
		
		private function handleComplete(e:ResourceLoaderCompleteEvent):void 
		{
			trace("complete...." + e.uid + " .. " + e.loaderTarget + " .. " + e.applicationDomain)
		}
		
		private function handleClassLoaded(e:ResourceLoaderClassLoadedEvent):void 
		{
			trace("class loaded..." + e.name + " .. " + e._class)
			trace("try to get the class again :: " + ResourceClasses.instance.getClass("example.package.SomeTestClassA"));
		}
		
		private function handleBundleLoaded(e:ResourceLoaderBundleCompleteEvent):void 
		{
			trace("bundle loaded..." + e.bundle)
		}
		
		private function handleAllRequiredLoaded(e:ResourceLoaderAllRequiredLoadedEvent):void 
		{
			trace("all required loaded..." + e.bundle)
		}
		
	}
	
}