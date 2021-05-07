;;

(defun *error* (msg)
  (if oldla (setvar "clayer" oldla))
  (if oldos (setvar "osmode" oldos))
  (if oldz0 (setvar "dimzin" oldz0))
  (if oldst (setvar "textstyle" oldst))
  (setvar "cecolor" "bylayer")
  (setvar "expert" 0)
  (prompt msg)
)

(defun get_current()
  (setq oldos (getvar "osmode"))
  (setq oldla (getvar "clayer"))
  (setq oldz0 (getvar "dimzin"))
  (setq oldst (getvar "textstyle"))
)

(defun rtn_current()
  (if oldla (setvar "clayer" oldla))
  (if oldos (setvar "osmode" oldos))
  (if oldz0 (setvar "dimzin" oldz0))
  (if oldst (setvar "textstyle" oldst))
)

(defun c:chk_gap1(/ #gap ss x_list y_list)
  (setvar "cmdecho" 0)
  (setq pass t)
  (get_current)
  (initget 7)
  (setq #gap (getreal "\nMin. gap: "))
  (setq ss (ssget '((0 . "LWPOLYLINE"))))
  (if ss (go_chk))
  (rtn_current)
  (princ)
)

(defun chk_right($case / p1 p2 p3 ent ssc pt1 pt2 $gap)
  (foreach pt_list x_list
    (setq p2 (nth 1 pt_list)
	  p3 (nth 2 pt_list)
	 ent (nth 4 pt_list))
    (if (= $case 1)
        (setq ssc (ssget "c" p3 (polar p2 0 #gap) '((0 . "LWPOLYLINE"))))
        (setq ssc (ssget "c" p3 (polar p2 0 #gap) '((0 . "LWPOLYLINE") (8 . "Check_Gap"))))
    )  
    (if (>= (sslength ssc) 2)
        (progn
	  (ssdel ent ssc)
	  (setq ent1 (ssname ssc 0))
	  (setq pt1 (polar p3 (* 0.5 pi) (* 0.5 (distance p2 p3))))
	  (vla-GetBoundingBox (vlax-ename->vla-object ent1) 'ptmin 'ptmax)
	  (setq p4 (vlax-safearray->list ptmin)
                p2 (vlax-safearray->list ptmax)
		p1 (list (car p4) (cadr p2))
	        p3 (list (car p2) (cadr p4)))
	  (setq pt2 (inters pt1 (polar pt1 0 1) p1 p4 nil))
	  (if (< (setq $gap (distance pt1 pt2)) #gap)
	      (progn
		(setq pass nil)
		(command ".dim" "hor" pt1 pt2 pt1 "" "exit")
	      )
	  )  
	)  
    )	  
  )
)  

(defun chk_up($case / p1 p2 p3 ent ssc pt1 pt2 $gap)
  (foreach pt_list y_list
    (setq p1 (nth 0 pt_list)
	  p2 (nth 1 pt_list)
	 ent (nth 4 pt_list))
    (if (= $case 1)
        (setq ssc (ssget "c" p1 (polar p2 (* 0.5 pi) #gap) '((0 . "LWPOLYLINE"))))
        (setq ssc (ssget "c" p1 (polar p2 (* 0.5 pi) #gap) '((0 . "LWPOLYLINE") (8 . "Check_Gap"))))
    )  
    (if (>= (sslength ssc) 2)
        (progn
	  (ssdel ent ssc)
	  (setq ent1 (ssname ssc 0))
	  (setq pt1 (polar p1 0 (* 0.5 (distance p1 p2))))
	  (vla-GetBoundingBox (vlax-ename->vla-object ent1) 'ptmin 'ptmax)
	  (setq p4 (vlax-safearray->list ptmin)
                p2 (vlax-safearray->list ptmax)
		p1 (list (car p4) (cadr p2))
	        p3 (list (car p2) (cadr p4)))
	  (setq pt2 (inters pt1 (polar pt1 (* 0.5 pi) 1) p3 p4 nil))
	  (if (< (setq $gap (distance pt1 pt2)) #gap)
	      (progn
		(setq pass nil)
		(command ".dim" "ver" pt1 pt2 pt1 "" "exit")
	      )
	  )  
	)  
    )	  
  )
)

(defun go_chk(/ p1 p2 p3 p4 n bump_list)
  (setvar "dimzin" 8)
  (setvar "expert" 2)
  (setvar "cecolor" "bylayer")
  (setvar "osmode" 0)
  (command ".insert" "dim_def" (getvar "viewctr") 1 1 0)
  (entdel (entlast))
  (command ".purge" "b" "dim_def" "n")
  (setvar "clayer" "Check_Gap")
  (command ".dimstyle" "r" "Check")
  (setq bump_list nil n 0)
  (repeat (sslength ss)
    (vla-GetBoundingBox (vlax-ename->vla-object (setq ent (ssname ss n))) 'ptmin 'ptmax)
    (setq p4 (vlax-safearray->list ptmin)
          p2 (vlax-safearray->list ptmax)
	  p1 (list (car p4) (cadr p2))
	  p3 (list (car p2) (cadr p4)))
    (setq bump_list (cons (list p1 p2 p3 p4 ent) bump_list))
    (setq n (1+ n))
  )
  (setq x_list (vl-sort bump_list '(lambda (s1 s2) (< (caar s1) (caar s2)))))
  (setq y_list (vl-sort bump_list '(lambda (s1 s2) (< (cadar s1) (cadar s2)))))
  (chk_right 1)
  (chk_up 1)
  (if pass (alert "Pass."))
)

(defun draw_rects()
  (setvar "dimzin" 8)
  (setvar "expert" 2)
  (setvar "cecolor" "bylayer")
  (setvar "osmode" 0)
  (command ".insert" "dim_def" (getvar "viewctr") 1 1 0)
  (entdel (entlast))
  (command ".purge" "b" "dim_def" "n")
  (setvar "clayer" "Check_Gap")
  (command ".dimstyle" "r" "Check")
  (setq bump_list nil n 0)
  (repeat (sslength ss)
    (vla-GetBoundingBox (vlax-ename->vla-object (setq ent (ssname ss n))) 'ptmin 'ptmax)
    (setq p4 (vlax-safearray->list ptmin) p2 (vlax-safearray->list ptmax))
    (setq xmin (car p4) ymin (cadr p4)
	  xmax (car p2) ymax (cadr p2))
    (setq ssc (ssget "c" p4 p2 '((0 . "LWPOLYLINE"))))
    (if ssc
        (progn
	  (setq nn 0)
	  (repeat (sslength ssc)
	    (vla-GetBoundingBox (vlax-ename->vla-object (setq ent (ssname ssc nn))) 'ptmin 'ptmax)
	    (setq p4 (vlax-safearray->list ptmin) p2 (vlax-safearray->list ptmax))
	    (if (< (setq tmp (car p4))  xmin) (setq xmin tmp))
	    (if (< (setq tmp (cadr p4)) ymin) (setq ymin tmp))
	    (if (> (setq tmp (car p2))  xmax) (setq xmax tmp))
	    (if (> (setq tmp (cadr p2)) ymax) (setq ymax tmp))
	    (setq nn (1+ nn))
	  )
	  (setq p1 (list xmin ymax)
		p2 (list xmax ymax)
		p3 (list xmax ymin)
		p4 (list xmin ymin))
	  (command ".pline" p1 p2 p3 p4 "c")
	  (setq bump_list (cons (list p1 p2 p3 p4 (entlast)) bump_list))
	)
    )
    (setq n (1+ n))
  )
  (setq x_list (vl-sort bump_list '(lambda (s1 s2) (< (caar s1) (caar s2)))))
  (setq y_list (vl-sort bump_list '(lambda (s1 s2) (< (cadar s1) (cadar s2)))))
  (chk_right 2)
  (chk_up 2)
  (command ".erase" (ssget "x" '((0 . "LWPOLYLINE") (8 . "Check_Gap"))) "")
  (if pass (alert "Pass."))
)	  

(defun c:chk_gap2(/ #gap txtgap txth ss x_list y_list)
  (setvar "cmdecho" 0)
  (setq pass t)
  (get_current)
  (initget 7)
  (setq #gap (getreal "\nMinimum gap: "))
  (setq txtgap (/ #gap 10)
	txth   (/ #gap 3))
  (setq blk (getstring "\nBlock name: "))
  (setq ss (ssget (list (cons 0 "INSERT") (cons 2 blk))))
  (if ss (draw_rects)) 
  (rtn_current)
  (princ)
)

(defun c:del_check(/ ss)
  (setvar "cmdecho" 0)
  (setq ss (ssget "x" '((0 . "DIMENSION") (8 . "Check_Gap"))))
  (if ss
     (progn
       (command ".erase" ss "")
       (command ".purge" "all" "*" "n")
     )  
  )
  (princ)
)
  