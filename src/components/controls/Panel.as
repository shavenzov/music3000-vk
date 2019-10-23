package components.controls
{
	import flash.filters.DropShadowFilter;
	
	import spark.components.Group;
	
	public class Panel extends Group
	{
		private var _color : uint = 0x333333;
		
		public function Panel()
		{
			super();
			filters = [ new DropShadowFilter( 2, 135 ) ];
		}
		
		public function get color() : uint
		{
			return _color;
		}
		
		public function set color( value : uint ) : void
		{
			_color = value;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			graphics.clear();
			graphics.beginFill( _color, 0.5 );
			graphics.drawRoundRect( 0, 0, unscaledWidth, unscaledHeight, 2, 2 );
			graphics.endFill();
		}
		
	}
}