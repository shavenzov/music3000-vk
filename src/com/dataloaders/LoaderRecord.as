package com.dataloaders
{
	import flash.events.IEventDispatcher;
	import flash.utils.getTimer;

	public class LoaderRecord
	{
		public var time : int;
		public var loader : Object;
		public var data : Object;
		public var params : Object;
		
		public function LoaderRecord( data : Object, loader : Object, params : Object = null ) : void
		{
			this.data = data;
			this.loader = loader;
			this.params = params;
			time = getTimer();
		}	
	}
}