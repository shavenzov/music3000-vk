package components.controls.timeScreenClasses
{
	import com.audioengine.core.TimeConversion;
	import com.utils.TimeUtils;
	
	import components.controls.timeScreenClasses.events.DisplayEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class TimeDisplay extends Display
	{
		private var _clockIcon : Sprite;
		private var _noteIcon  : Sprite;
		
		/**
		 * Текущее положение в фреймах 
		 */		
		private var _position : Number = 0;
		
		private var _bpm : Number = 0;
		
		/**
		 * Отображать время в тактах/долях или в минутах/секундах  
		 */		
		private var _inMeasures : Boolean = true;
		
		public function TimeDisplay()
		{
			super();
		}
		
		public function get inMeasures() : Boolean
		{
			return _inMeasures;
		}
		
		public function set inMeasures( value : Boolean ) : void
		{
			if ( _inMeasures != value )
			{
				_inMeasures = value;
				invalidateProperties();
				invalidateDisplayList();
			}
		}
		
		public function get position() : Number
		{
			return _position;
		}
		
		public function set position( value : Number ) : void
		{
			_position = value;
			invalidateProperties();
		}
		
		public function get bpm() : Number
		{
			return _bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			_bpm = value;
			invalidateProperties();
		}
		
		private function onClick( e : MouseEvent ) : void
		{
			_inMeasures = ! _inMeasures;
			invalidateProperties();
			invalidateDisplayList();
			
			dispatchEvent( new Event( DisplayEvent.VIEW_TYPE_CHANGED ) );
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_clockIcon = new Assets.CLOCK_ICON();
			_noteIcon  = new Assets.NOTE_ICON();
			
			_clockIcon.width = _clockIcon.height = 16;
			_noteIcon.width  = _noteIcon.height = 16;
			
			addChild( _clockIcon );
			addChild( _noteIcon );
			
			addEventListener( MouseEvent.CLICK, onClick );
			
			numDigits = 6;
		}
		
		private static const padding_left : Number = 4;
		private static const gap : Number = 4;
		
		override protected function measure():void
		{
			super.measure();
			measuredWidth += padding_left + _clockIcon.width + gap;
		}
		
		override protected function commitProperties():void
		{
			if ( _inMeasures )
			{
				text = TimeUtils.formatbarsToMusicalTime( TimeConversion.numSamplesToBars( _position, _bpm ) );
				toolTip = 'Щелкни для отображения времени в формате минуты / секунды';
			}
			else
			{
				text = '0' + TimeUtils.formatMiliseconds3( TimeConversion.numSamplesToMiliseconds( _position ) );
				toolTip = 'Щелкни для отображения времени в формате такты / доли';
			}
			
			_clockIcon.visible = ! _inMeasures;
			_noteIcon.visible  = _inMeasures;
			
			super.commitProperties();
			
			onDigits[ 0 ].visible = ! ( text.charAt( 0 ) == '0' );
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var icon : Sprite = _inMeasures ? _noteIcon : _clockIcon;
			
			icon.y = ( unscaledHeight - icon.height ) / 2 + 1;
			icon.x = padding_left;
			
			var pos : Number = icon.x + icon.width + gap;
			
			var i : int = 0;
			
			while( i < offDigits.length )
			{
				var on  : TextField = onDigits[ i ];
				var off : TextField = offDigits[ i ];
				
				if ( i == 3 )
				{
					off.visible = false;
					on.x = pos;
					on.y = ( unscaledHeight - on.height ) / 2;
					
					pos += on.width;
				}
				else
				{
					off.x = pos;
					off.y = ( unscaledHeight - off.height ) / 2;
					
					on.x = pos;
					on.y = off.y;
					on.width = off.width;
					
					pos += off.width;
				}
				
				i ++;
			}
			
			graphics.beginFill( 0xffffff, 0.0 );
			graphics.drawRect( 0, 0, unscaledWidth, unscaledHeight );
			graphics.endFill();
		}
		
	}
}