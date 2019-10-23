package components.sequencer.timeline
{
	import components.ScrollableBase;
	
	import flash.display.BlendMode;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class RectSelection extends ScrollableBase 
	{
		public var rect : Rectangle = new Rectangle();
		private var _scrollRect : Rectangle;
		private var startPos : Point;
		private var endPos : Point;
		
		private var borderColor : uint = 0x000000;
		private var fillColor   : uint = 0xFFD700;
		
		public function RectSelection()
		{
			super();
			blendMode = BlendMode.HARDLIGHT;
		}	
		
		public function setRectPoint( startPos : Point, endPos : Point ) : void
		{	
			this.startPos = startPos;
			this.endPos   = endPos; 
			updateRect();
			update();
		}
		
		private function updateRect() : void
		{	
			if ( startPos.x < endPos.x )
			{
				rect.x = startPos.x;
				rect.right = endPos.x;
			}
			else
			{
				rect.x = endPos.x;
				rect.right = startPos.x;
			}
			
			if ( startPos.y < endPos.y )
			{
				rect.y = startPos.y;
				rect.bottom = endPos.y;
			}
			else
			{
				rect.y = endPos.y;
				rect.bottom = startPos.y;
			}
		}	
		
		override protected function update():void
		{
			graphics.clear();
			
			//Невидимый прямоугольник
			graphics.beginFill( 0xFFFFFF, 0.0 );
			graphics.drawRect( 0, 0, scrollWidth, scrollHeight );
			graphics.endFill();
			
			if ( rect.width > 0 )
			{
				var intersection : Rectangle = _scrollRect.intersection( rect );
			
				if ( intersection.width > 0 )
				{
					//Прямоугольник выделения
					graphics.lineStyle( 1, borderColor, 0.85 );
					graphics.beginFill( fillColor, 0.3 );
					graphics.drawRect( intersection.x - _hsp, intersection.y - _vsp,
						                  intersection.width, intersection.height );
					graphics.endFill();
				}
			}		
		}	
		
		override public function updateScrollRect():void
		{
			if ( _scrollRectChanged )
			{
				
				_scrollRect = new Rectangle( _hsp, _vsp, scrollWidth  < contentWidth  ? scrollWidth  : contentWidth,
					                                     scrollHeight < contentHeight ? scrollHeight : contentHeight );
				
				
				update();
				_scrollRectChanged = false;
			}	
		}	
	}
}