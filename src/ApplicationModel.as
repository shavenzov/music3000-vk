package
{
	import classes.tasks.project.ProjectTask;
	
	import components.library.Library;
	import components.sequencer.VisualSequencer;
	import components.welcome.payments.UserInfo;
	
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	
	import mx.core.FlexGlobals;

	public class ApplicationModel
	{
		//Ссылка на библиотеку
		public static var library : Library;
		//Ссылка на панель инструментов
		public static var bottomPanel : BottomPanel;
		//Ссылка на панель инструментов
		public static var topPanel : TopPanel;
		//Ссылка на Менеджер проекта
		public static var project : ProjectTask;
		//Ссылка на VisualSequencer
		public static var vs : VisualSequencer;
		//Ссылка на панель отображения информации о пользователе
		public static var userInfo : UserInfo;
		
		//Если приложение в полноэкранном режиме, то переключает в оконный
		public static function exitFromFullScreen() : void
		{
			var stage : Stage = FlexGlobals.topLevelApplication.stage;
			
			if ( ( stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE ) ||
				( stage.displayState == StageDisplayState.FULL_SCREEN ) 
			)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		public static function get fullScreen() : Boolean
		{
			var stage : Stage = FlexGlobals.topLevelApplication.stage;
			
			return stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE;
		}
		
		public static function set fullScreen( value : Boolean ) : void
		{
			var stage : Stage = FlexGlobals.topLevelApplication.stage;
			
			try
			{
				stage.displayState = value ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
			}
			catch (err:SecurityError) {
				// ignore
			}
		}
	}
}