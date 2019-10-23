package components.library
{
	import flash.display.DisplayObject;

	public interface ILibraryModule
	{
		/**
		 * Компонент относительно которого будет отображаться строка поиска ( над этим компонентом )  
		 * @return 
		 * 
		 */		
		function get mainComponent() : DisplayObject;
		
		//Текст строки поиска
		function get searchText() : String;
		function set searchText( value : String ) : void;
		
		//В результате поиска отображать только избранные сэмплы
		function get showOnlyFavorite() : Boolean;
		function set showOnlyFavorite( value : Boolean ) : void;
		
		//Отображать ли строку поиска
		function get searchBoxEnabled() : Boolean;
		
		//Инициализирован ли модуль библиотеки (готов к работе)
		function get ready() : Boolean;
		
		//Запускает процесс поиска
		function search() : void;
		
		//Сбрасывает все параметры поиска
		function reset() : void;
	}
}