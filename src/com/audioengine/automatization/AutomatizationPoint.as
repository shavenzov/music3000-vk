package com.audioengine.automatization
{
	import mx.core.mx_internal;
	
	use namespace mx_internal;
	
	public class AutomatizationPoint
	{
		/**
		 * Положение точки на дорожке 
		 */		
		public var position : Number;
		
		/**
		 * Значение точки 
		 */		
		public var value    : Number;
		
		/**
		 * Идентификатор точки 
		 */		
		private var _id     : uint;
		
		public function AutomatizationPoint( position : Number = 0.0, value : Number = 0.0  )
		{
		  super();
			
		  this.position = position;
		  this.value    = value;
		}
		
		public function get id() : uint
		{
			return _id;
		}
		
		mx_internal function setId( value : uint ) : void
		{
			_id = value;
		}
		
		public function clone() : AutomatizationPoint
		{
			var point : AutomatizationPoint = new AutomatizationPoint( position, value );
			    point.setId( _id );
				
			return point;	
		}
	}
}