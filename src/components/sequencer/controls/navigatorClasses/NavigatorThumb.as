package components.sequencer.controls.navigatorClasses
{
	import components.Base;
	
	import flash.display.BlendMode;
	import flash.events.MouseEvent;
	
	public class NavigatorThumb extends Base
	{
		public var toLeftButton  : LeftResizeButton;
		public var toRightButton : RightResizeButton;
		
		private var _mouseDown : Boolean;
		
		public function NavigatorThumb()
		{
			super();
			
			toLeftButton  = new LeftResizeButton();
			toLeftButton.touch();
			//toLeftButton.visible = false;
			
			toRightButton = new RightResizeButton();
			toRightButton.touch();
			//toRightButton.visible = false;
			
			addChild( toLeftButton );
			addChild( toRightButton );
			
			//addEventListener( MouseEvent.ROLL_OVER, onRollOver, false, 1000 );
			//addEventListener( MouseEvent.ROLL_OUT, onRollOut, false, 1000 );
			
			//blendMode = BlendMode.INVERT;
		}
		/*
		private function onRollOver( e : MouseEvent ) : void
		{			
			if ( _mouseDown ) return;
			
			toLeftButton.visible = true;
	        toRightButton.visible = true;	
		}
		
		private function onRollOut( e : MouseEvent ) : void
		{
			if ( _mouseDown ) return;
			toLeftButton.visible = false;
			toRightButton.visible = false;
		}
		*/
		public function get mouseDown() : Boolean
		{
			return _mouseDown;
		}
		
		public function set mouseDown( value : Boolean ) : void
		{
			_mouseDown = value;
			/*
			if ( value )
			{
				onRollOver( null );
			}
			else
			{
				if ( ! getBounds( this ).contains( mouseX, mouseY ) )
				{
					onRollOut( null );
				}
				else
				{
					onRollOver( null );
				}
			}*/
		}
		
		private function draw() : void
		{
			graphics.clear();
			graphics.lineStyle( 1, 0xFFFFFF );
			graphics.beginFill( 0xFFFFFF, 0.0 );
			graphics.drawRect( 0, 0, contentWidth, contentHeight - 1 );
			graphics.endFill();
		}	
		
		override protected function update() : void
		{
			toLeftButton.x = - 2;
			toLeftButton.contentHeight = contentHeight;
			toLeftButton.invalidateAndTouchDisplayList();
			
			toRightButton.x = contentWidth - 2 + 1;
			toRightButton.contentHeight = contentHeight;
			toRightButton.invalidateAndTouchDisplayList();
			
			draw();
		}	
	}
}