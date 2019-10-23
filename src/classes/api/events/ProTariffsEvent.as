package classes.api.events
{
	import flash.events.Event;
	
	public class ProTariffsEvent extends Event
	{
		public static const PRO_TARIFFS : String = 'PRO_TARIFFS';
		
		public var tariffs : Array;
		public var time    : Date;
		
		public function ProTariffsEvent( type : String, tariffs : Array, time : Date )
		{
			super(type);
			this.tariffs = tariffs;
			this.time    = time;
		}
		
		override public function clone() : Event
		{
			return new ProTariffsEvent( type, tariffs, time );
		}
	}
}