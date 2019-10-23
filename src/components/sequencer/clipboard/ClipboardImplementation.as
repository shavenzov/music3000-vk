package components.sequencer.clipboard
{
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class ClipboardImplementation extends EventDispatcher
	{
		public function ClipboardImplementation()
		{
		  super();
		}
		
		/**
		 * Тип данных хранящихся в буфере обмена 
		 */		
		public var dataType : int;
		
		/**
		 * Данные буфера обмена 
		 */		
		public var data : Object;
		
		public function set( data : Object, dataType : int ) : void
		{
			this.data     = data;
			this.dataType = dataType;
			
			dispatchEvent( new Event( Event.CHANGE ) );
		}
		
		public function clear() : void
		{
			data = null;
			dataType = Clipboard.NONE;
			
			dispatchEvent( new Event( Event.CHANGE ) );
		}	
	}
}