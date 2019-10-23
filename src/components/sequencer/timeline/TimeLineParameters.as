package components.sequencer.timeline
{
	import com.audioengine.core.AudioData;

	public class TimeLineParameters
	{
		/**
		 * Размер зоны прокрутки слева и справа по горизонтали
		 */	
		public static const AUTO_SCROLL_AREA_X : Number = 100.0;
		
		/**
		 * 
		 * Размер зоны прокрутки сверху 
		 */		
		public static const AUTO_SCROLL_AREA_TOP : Number = 40.0;
		
		/**
		 * 
		 * Размер зоны прокрутки снизу 
		 */	
		public static const AUTO_SCROLL_AREA_BOTTOM : Number = 60.0;
		
		/**
		 * Маскимальное количество дорожек которое можно создать 
		 */		
		public static const MAX_NUM_TRACKS : int = 15;
		
		/**
		 * Масштаб по умолчанию 
		 */		
		public static const DEFAULT_SCALE : Number = 1000;
		
		/**
		 * Минимальный допустимый масштаб 
		 */		
		public static const MIN_SCALE : Number = 370;
		
		/**
		 * Минимальная длина микса, которую можно установить 
		 */		
		public static const MIN_DURATION : Number = 300 * AudioData.RATE; //5 минут.
	}
}