package components.controls.timeScreenClasses
{
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import mx.core.FTETextField;
	import mx.core.UIComponent;
	
	public class Display extends UIComponent
	{
		private static const NUMBER_ON_COLOR  : uint = 0xEF8200;
		private static const NUMBER_OFF_COLOR : uint = 0x282828;
		
		protected const offDigits : Vector.<TextField> = new Vector.<TextField>();
		protected const onDigits  : Vector.<TextField> = new Vector.<TextField>();
		
		private var _numDigits : int = 0;
		private var _numDigitsChanged : Boolean;
		
		private var _text : String;
		private var _textChanged : Boolean;
		
		public function Display()
		{
			super();
		}
		
		protected function createDigit( on : Boolean ) : TextField
		{
			var digit : TextField = new TextField();
			    digit.defaultTextFormat = new TextFormat( 'Digital', 28, on ? NUMBER_ON_COLOR : NUMBER_OFF_COLOR );
				digit.embedFonts = true;
				digit.selectable = false;
				digit.autoSize   = TextFieldAutoSize.RIGHT;
				
				if ( ! on )
				{
					digit.text = '8';
				}
				
			return digit;	
		}
		
		private function populateDigits( num : int ) : void
		{
			var i : int = onDigits.length;
			var digitOn  : TextField;
			var digitOff : TextField
			
			if ( num > onDigits.length )
			{
				while( i != num )
				{
					digitOn  = createDigit( true );
					digitOff = createDigit( false );
					
					onDigits.push( digitOn );
					offDigits.push( digitOff );
					
					addChild( digitOn );
					addChild( digitOff );
					
					i ++;
				}
		
			}
			else if ( num < onDigits.length )
			{
				while( i != num )
				{
					removeChild( onDigits.pop() );
					removeChild( offDigits.pop() );
					
					i --;
				}
			}
			
			for each( digitOff in offDigits )
			{
				setChildIndex( digitOff, 0 );
			}
		}
		
		private function setText( text : String ) : void
		{
			var i : int = 0;
			
			while( i < onDigits.length )
			{
				onDigits[ i ].text = text.charAt( i );
				
				i ++;
			}
		}
		
		public function get numDigits() : int
		{
		  return _numDigits;
		}
		
		public function set numDigits( value : int ) : void
		{
			if ( value != _numDigits )
			{
				_numDigits = value;
				_numDigitsChanged = true;
				
				invalidateProperties();
			}
		}
		
		public function get text() : String
		{
			return _text;
		}
		
		public function set text( value : String ) : void
		{
			if ( value != _text )
			{
				_text = value;
				_textChanged = true;
				invalidateProperties();
			}
		}
		
		protected function digitsVisible( visible : Boolean ) : void
		{
			var i : int = 0;
			
			while( i < _numDigits )
			{
				onDigits[ i ].visible = visible;
				offDigits[ i ].visible = visible;
				i ++;
			}
		}
		
		override protected function measure():void
		{
			if ( offDigits.length > 0 )
			{
				measuredWidth  = offDigits[ 0 ].width * _numDigits;
				measuredHeight = offDigits[ 0 ].height;	
			}
			else
			{
				measuredWidth = 0;
				measuredHeight = 0;
			}
		}
		
		override protected function commitProperties():void
		{
			if ( _numDigitsChanged )
			{
				populateDigits( _numDigits );
				_numDigitsChanged = false;
				invalidateSize();
				invalidateDisplayList();
			}
			
			if ( _textChanged )
			{
				setText( _text );
				_textChanged = false;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var i : int = 0;
			var pos : Number = 0;
			
			while( i < offDigits.length )
			{
				offDigits[ i ].x = pos;
				onDigits[ i ].y = pos;
				
				pos += offDigits[ i ].width;	
				i ++;
			}
		}
		
	}
}