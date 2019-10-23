package mx.managers.history
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class History
	{
		/**
		 * Максимальное количество запоминаемых событий 
		 */		
		private static const MAX_HISTORY : int = 100;
		
		/**
		 * Череда событий 
		 */		
		public static var events : Vector.<HistoryRecord> = new Vector.<HistoryRecord>();
		
		/**
		 * Текущий индекс в списке истории 
		 */		
		private static var _index : int = -1;
		
		/**
		 * Идет процесс сбора событий 
		 */		
		private static var _catching   : Boolean;
		/**
		 * Количество вызовов метода startCatching 
		 */		
		private static var _startCatchicngCount : int = 0;
		
		public static var recordHook : HistoryRecord;
		
		public static const listener : EventDispatcher = new EventDispatcher();
		
		/**
		 * Вкл/Выкл 
		 */		
		public static var enabled : Boolean = true;
		
		/**
		 * Идет процесс сбора событий для отмены определенного действия
		 */	
		public static function get catching() : Boolean
		{
			return _catching;
		}
		
		/**
		 * Добавляет событие в список 
		 * @param event
		 * 
		 */		
		public static function add( event : HistoryRecord ) : void
		{	
			if ( ! enabled ) return;
			
			trace( 'addHistoryRecord', event.backName, event.forwardName );
			
			if ( _catching )
			{
				if ( recordHook )
				{
					recordHook.add( event.back, event.forward );
					
					if ( ! recordHook.backName )
					{
						recordHook.backName = event.backName;
					}
					
					if ( ! recordHook.forwardName )
					{
						recordHook.forwardName = event.forwardName;
					}
				}
				else
				{
					recordHook = event;
				}
				
				return;
			}	
			
			//Отсекаем все события после индекса
			if ( _index < events.length - 1 )
			{
				events = events.slice( 0, _index + 1 );
			}
			
			if ( events.length == MAX_HISTORY )
			{
				events.shift();
				events.push( event );
			}
			else
			{
				events.push( event );
				_index ++;
			}
			
			listener.dispatchEvent( new Event( Event.CHANGE ) );
		}
		
		/**
		 * Запускает режим сбора событий 
		 * 
		 */		
		public static function startCatching() : void
		{
			if ( ! enabled ) return;
			
			if ( ! _catching )
			{
				_catching = true;
			}
			
			_startCatchicngCount ++;
		}
		
		/**
		 * Останавливает режим сбора событий и формирует событие 
		 * reverseBack - инвентировать список команд в back
		 */		
		public static function stopCatching( reverseBack : Boolean = true ) : void
		{
			if ( ! enabled ) return;
			
			_startCatchicngCount --;
			
			if ( _startCatchicngCount == 0 )
			{
				if ( _catching )
				{
					_catching = false;
					
					if ( recordHook )
					{
						if ( reverseBack && recordHook.back.length > 1 )
						{
							recordHook.back.reverse();
						}
						
						add( recordHook );
					}
					
					recordHook = null;
				}
			}	
		}	
		
		/**
		 * Индекс курсора истории 
		 * @return 
		 * 
		 */		
		public static function get index() : int
		{
		  return _index;
		}
		
		/**
		 * Количество событий в списке истории 
		 * @return 
		 * 
		 */		
		public static function get length() : int
		{
			return events.length;
		}	
		
		/**
		 * Проверяет можно ли откатиться назад по истории  
		 * @return 
		 * 
		 */		
		public static function isCanUndo() : Boolean
		{	
			return _index != -1;
		}
		
		/**
		 * Проверяет можно ли продвинуться вперед по истории 
		 * @return 
		 * 
		 */		
		public static function isCanRedo() : Boolean
		{
			return _index < events.length - 1;
		}
		
		/**
		 * Название операции которая будет повторять действие
		 * @return 
		 * 
		 */		
		public static function undoOpName() : String
		{
			return events[ _index ].backName;
		}
		
		/**
		 * Название операции которая будет выполнять отмену действия 
		 * @return 
		 * 
		 */	
		public static function redoOpName() : String
		{
			return events[ _index + 1 ].forwardName;
		}	
		
		/**
		 * Назад на одно действие 
		 * 
		 */		
		public static function undo( sendChangeEvent : Boolean = true ) : void
		{
			events[ _index ].goBack();
			_index --;
			
			if ( sendChangeEvent )
			{
				listener.dispatchEvent( new Event( Event.CHANGE ) );
			}	
		}
		
		/**
		 * Вперед на одно действие 
		 * 
		 */		
		public static function redo( sendChangeEvent : Boolean = true ) : void
		{	
			_index ++;
			
			events[ _index ].goForward();
			
			if ( sendChangeEvent )
			{
				listener.dispatchEvent( new Event( Event.CHANGE ) );
			}
		}
		
		/**
		 * Очищает историю событий 
		 * 
		 */		
		public static function clear() : void
		{	
			events.length = 0;
			_index        = -1;
			_catching      = false;
			recordHook    = null;
			listener.dispatchEvent( new Event( Event.CHANGE ) );
		}
	}
}