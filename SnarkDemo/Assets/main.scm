(do (define setColor (lambda (colorName)
			(do (define window (@ (@ (@ UIApplication sharedApplication) delegate) window))
			    (@ window setBackgroundColor: (@ NSColor colorName)))))
    (setColor orangeColor))
