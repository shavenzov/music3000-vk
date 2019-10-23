package components.sequencer.timeline
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.TimeConversion;
	import components.ScrollableBase;
	
	public class BaseTracker extends ScrollableBase implements IScale
	{
		include 'incs/gridutils.as'
		
		/**
		 * Как отображать сетку
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах 
		 */		
		private var _measureType : int = MeasureType.MEASURES;
		
		/**
		 * Скорость воспроизведения ( ударов в минуту ) 
		 */		
		protected var _bpm : Number = 140;
		protected var _bpmChanged : Boolean;
		
		/**
		 * Шаг засечек в фреймах масштабе 1:1 ( для режима отрисовки сетки MeasureType.SECONDS )
		 */		
		public var _division : Number = AudioData.RATE;
		
		/**
		 *Масштаб Количество секунд в пикселе
		 *Это значение используется для определения длины трека по умолчанию на основании _duration 
		 */
		protected var _scale        : Number = 1/25;
		
		/**
		 *Длина объекта в секундах 
		 * 
		 */
		protected var _duration        : Number = 3;
		
		/**
		 * Необходим перерасчитать параметры перед отрисовкой 
		 */		
		private var _needRecalc : Boolean;
			
		/**
		 * Количество отображаемых дорожек 
		 */		
		protected var _numTracks : int = 0;
		
		/**
		 * Высота каждой из дорожек 
		 */		
		public var _trackHeight : Number = Settings.TRACK_HEIGHT;
		
		
		/**
		 * Текущий интервал залипания 
		 */		
		protected var _stickInterval : Number;
		
		
		
		public function BaseTracker()
		{
			super();
		}
		
		public function get stickInterval() : Number
		{
			return _stickInterval;
		}	
		
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(value:Number):void
		{
			if ( _scale != value )
			{  
				_scale = value;
				
				_needMeasure = true;
				_needUpdate  = true;
			}
		}
		
		public function get duration():Number
		{
			return _duration;
		}
		
		public function set duration(value:Number):void
		{
			if ( _duration != value )
			{
				_duration = value;
				
				_needMeasure = true;
				_needUpdate = true;
			}
		}
		
		/**
		 * Количество отображаемых дорожек 
		 */
		public function get numTracks() : int
		{
			return _numTracks;
		}
		
		public function set numTracks( value : int ) : void
		{
			_numTracks = value;
		}	
		
		override protected function update():void
		{
			calculateCurrentDivision();
		}	
		
		override protected function measure() : void	
		{
			contentWidth  = _duration / _scale;
			contentHeight = _numTracks * _trackHeight;
		}
		
		private function calculateCurrentDivision() : void
		{
			if ( _measureType == MeasureType.MEASURES )
			{
				_stickInterval      = TimeConversion.bitsToNumSamples( 1, _bpm );
				return;
			}
			
			if ( _measureType == MeasureType.SECONDS )
			{
				_stickInterval   = _division;
				return;
			}
		}	
		
		public function get measureType() : int
		{
			return _measureType;
		}
		
		public function set measureType( value : int ) : void
		{
			if ( _measureType != value )
			{
				_measureType = value;
				_needUpdate = true;
			}	
		}
		
		public function get bpm() : int
		{
			return _bpm;
		}
		
		public function set bpm( value : int ) : void
		{
			if ( _bpm != value )
			{
				_bpm = value;
				_bpmChanged = true;
				_needUpdate = true;	
			}
		}
	}
}