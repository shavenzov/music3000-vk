package classes.api.events
{
	import flash.events.Event;
	
	public class PublisherUploadEvent extends Event
	{
		public static const UPLOAD : String = 'UPLOAD';
		
		/**
		 * Количество записанных данных 
		 */		
		public var wrote : uint;
		/**
		 * Размер блока переданных данных 
		 */		
		public var size  : uint;
		/**
		 * Общий размер уже записанных данных 
		 */		
		public var total : uint;
		/**
		 * Если, true то все данные на сервере 
		 */		
		public var done  : Boolean;
		
		public function PublisherUploadEvent( type : String, wrote : uint, size : uint, total : uint, done : Boolean )
		{
			super( type );
			
			this.wrote = wrote;
			this.size  = size;
			this.total = total;
			this.done  = done;
		}
		
		override public function clone() : Event
		{
			return new PublisherUploadEvent( type, wrote, size, total, done );
		}
	}
}