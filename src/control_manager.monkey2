Class Control
	Field Trigger:Bool()
	Field Callback:Void()
	Field Enabled:Bool = True	
End


Class ControlManager
	
	Field Controls := New Map<String,Control>
	
	Method Add ( key:String, trigger:Bool(), callback:Void() )
		Local control := New Control()
		control.Trigger = trigger
		control.Callback = callback
		
		Controls.Add( key, control )
	End
	
	Method Remove ( key:String )
		Controls.Remove( key )
	End
	
	Method Disable ( key:String )
		Controls.Get( key ).Enabled = False
	End
	
	Method Enable ( key:String )
		Controls.Get( key ).Enabled = True
	End
	
	Method DisableAll ()
		For Local key := Eachin Controls.Keys
			Disable( key )
		Next	
	End
	
	Method EnableAll ()
		For Local key := Eachin Controls.Keys
			Enable( key )
		Next	
	End
	
	Method OnUpdate ()
		For Local control := Eachin Controls.Values
			If control.Enabled And control.Trigger()
				control.Callback()
			End
		Next		
	End
	
End
