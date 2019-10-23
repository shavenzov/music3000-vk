package components.sequencer.controls
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	
	import mx.core.IUITextField;
	import mx.core.UIComponent;
	import mx.core.UIFTETextField;
	
	public class TrackNumber extends UIComponent
	{
		private var _label : IUITextField;
		private var bg    : Shape;
		
		public function TrackNumber()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			bg = new Shape();
			//bg.graphics.lineStyle( 1.0, 0xD6D6D6, 1.0, false, LineScaleMode.NONE );
			bg.graphics.beginFill( 0x000000, 0.5 );
			bg.graphics.drawRoundRectComplex( 0, 0, 60, 60, 0, 0, 0, 0 );
			bg.graphics.endFill();
			
			_label = IUITextField( createInFontContext( UIFTETextField ) );
			
			var nStyleName : String = getStyle( 'numberTextStyle' );
			if ( nStyleName )
			{
				_label.styleName = nStyleName;
			}
			
			addChild( bg );
			addChild( DisplayObject( _label ) );
		}
		
		public function get label() : String
		{
			return _label.text;
		}
		
		public function set label( value : String ) : void
		{
			_label.text = value;
			invalidateSize();
			invalidateDisplayList();
		}
		
		override protected function measure() : void
		{
			measuredWidth = _label.getExplicitOrMeasuredWidth();
			measuredHeight = _label.getExplicitOrMeasuredHeight();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			bg.width = unscaledWidth;
			bg.height = unscaledHeight;
			
			_label.setActualSize( _label.getExplicitOrMeasuredWidth(), _label.getExplicitOrMeasuredHeight() );
			_label.move( ( unscaledWidth - _label.width ) / 2, ( unscaledHeight - _label.height ) / 2 );
		}
	}
}