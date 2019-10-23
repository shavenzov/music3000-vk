package components.sequencer.controls
{
	import components.circularknob.CircularKnob;
	
	import flash.display.DisplayObject;
	
	import mx.core.IUITextField;
	import mx.core.UIFTETextField;
	
	public class SoundPanKnob extends CircularKnob
	{
		private var _left  : IUITextField;
		private var _right : IUITextField;
		
		public function SoundPanKnob()
		{
			super();
			minValue = -1;
			maxValue = 1;
			minRotation = 80;
			maxRotation = 280;
			
			sticking = true;
			stickingArea = 0.05;
			stickingValues = Vector.<Number>( [ -0.5, 0.0, 0.5 ] );
		}
		
		override protected function formatToolTipValue( v : Number ) : String
		{
			return getFormatedValue( v );
		}
		
		public static function getFormatedValue( v : Number ) : String
		{
			var left  : Number = 1;
			var right : Number = 1;
			
			
			if ( v > 0.0 )
			{
				left = 1.0 - v;
				right = 1.0;
			}
			else
			{
				right = 1.0 + v;
				left = 1.0;
			}
			
			left = Math.round( left * 100.0 );
			right = Math.round( right * 100.0 );
			
			return "Слева   : " + left + '%\n' +
				"Справа : " + right + '%'; 
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_left  = IUITextField( createInFontContext( UIFTETextField ) );
			_left.text = 'Л';
			_right = IUITextField( createInFontContext( UIFTETextField ) );
			_right.text = 'П';
			
			addChild( DisplayObject( _left ) );
			addChild( DisplayObject( _right ) );
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			_left.setActualSize( _left.getExplicitOrMeasuredWidth(), _left.getExplicitOrMeasuredHeight() );
			_left.move( 0, unscaledHeight - _left.height - 3 );
			
			_right.setActualSize( _right.getExplicitOrMeasuredWidth(), _right.getExplicitOrMeasuredHeight() );
			_right.move( unscaledWidth - _right.width, unscaledHeight - _right.height - 3 );
		}	
	}
}