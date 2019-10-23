package classes.soundwave
{
	import com.audioengine.core.IAudioData;
	
	import flash.display.BitmapData;
	import flash.events.IEventDispatcher;

	public interface ISoundWaveGraphic extends IEventDispatcher
	{
		function get id() : String;
		
		function get w() : int;
		function set w( value : int ) : void;
		
		function get h() : Number;
		function set h( value : Number ) : void
		
		function copy( srcOffset : int, length : int ) : Vector.<BitmapData>;
		function update() : void; //Обновляет часть волны, для асинхронной отрисовки
		function updateNow() : void; //Синхронно полностью обновляет звуковую волну
		function updateChangedData() : void //Синхронно обновляет участок волны с изменившимимся данными
		
		function attach() : void; //Увеличить количество ссылок на звуковую волну
		function dettach() : void; //Уменьшить количество ссылок на звуковую волну
		function get links() : int; //Количество ссылок на данную волну
		
		function get data() : IAudioData; //Данные для отрисовки
		
		function get bpmChange() : Boolean; //Волна должна перерисовываться при изменении bpm
		function get scaleChange() : Boolean; //Волна должна перерисовываться при изменении масштаба 
		
		function get needUpdate() : Boolean; //Указывает, что волну необходимо перерисовать
		function set needUpdate( value : Boolean ) : void;
		
		function startUpdate() : void; //Иницииализирует процесс обновления волны
		function endUpdate() : void; //Завершает процесс обновления волны
		
		function get iterations() : int; //Сколько раз необходимо вызвать метод update для полного рендеринга звуковой волны
		function get currentIteration() : int; //Текущая итерация рендеринга звуковой волны
		function get rendering() : Boolean; //Указывает что в настоящий момент звуковая волна в стадии отрисовки
		
        /*
		Указывает, что объект заблокирован потоком и обновлять объект синхронно запрещенно
		*/
		function get locked() : Boolean;
		function set locked( value : Boolean ) : void;
		
		function clear() : void;
	}
}