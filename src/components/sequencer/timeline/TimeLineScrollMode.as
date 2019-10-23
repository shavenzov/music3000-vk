package components.sequencer.timeline
{
	public class TimeLineScrollMode
	{
			/*
			Перечисления режимов поведения при перемещении ползунка воспроизведения во время воспроизведения
			*/
			
			/**
			 * Автопрокурутка отключена 
			 */		
			public static const NO_SCROLL : int = 0;
			
			/**
			 * При прокрутке курсор будет пытаться оказываться по середине окна 
			 */		
			public static const PLAYHEAD_CENTERED : int = 1;
			
			/**
			 * При перемещении курсора к краю окна будет происходить переход к следующему окну
			 */		
			public static const SCROLL_ON_NEXT_VIEW : int = 2;
			
			/**
			 * Плавная прокрутка при перемещении курсора к левой или правой границе 
			 */			
			public static const SCROLL_ON_LEFT_AND_RIGHT_AREA : int = 3;
			
	}
}