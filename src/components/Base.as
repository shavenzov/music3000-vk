package components
{
	import flash.display.Sprite;
	
	public class Base extends Sprite
	{
		protected var _needUpdate  : Boolean = true;
		protected var _needMeasure : Boolean = true;
		
		public var contentWidth  : Number = 0;
		public var contentHeight : Number = 0;
		
		public function Base()
		{
			super();
		}	
		
		public function touch() : void
		{
			if ( _needMeasure )
			{
				_needMeasure = false;
				measure();
			}	
				
			if ( _needUpdate )
			{
				_needUpdate = false;
				update();
			}	
		}
		
		public function invalidate() : void
		{
			_needUpdate = true;
			_needMeasure = true;
		}
		
		public function invalidateDisplayList() : void
		{
			_needUpdate = true;
		}
		
		public function invalidateAndTouchDisplayList() : void
		{
			_needUpdate = true;
			touch();
		}	
		
		public function invalidateAndTouch() : void
		{
			invalidate();
			touch();
		}	
		
		protected function update() : void
		{
		
		}
		
		protected function measure() : void
		{
			
		}	
	}
}