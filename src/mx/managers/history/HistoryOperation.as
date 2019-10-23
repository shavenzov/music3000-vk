/**
 * Запись в истории событий 
 */
package mx.managers.history
{
	public class HistoryOperation
	{
		private var obj    : Object;
		private var action : Function;
		private var params : Array;
		
		public function HistoryOperation( obj : Object, action : Function, ...params )
		{
		  super();
		  
		  this.obj    = obj;
		  this.action = action;
		  this.params = params;
		}
		
		public function call() : void
		{
			action.apply( obj, params ); 
		}	
	}
}