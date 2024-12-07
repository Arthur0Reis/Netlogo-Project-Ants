turtles-own [
  is-predator?    ;; True se for predador, falso para formiga
]

patches-own [
  chemical             ;; quantidade de feromônio no patch
  food                 ;; quantidade de comida no patch (0, 1 ou 2)
  nest?                ;; verdadeiro para patches do ninho, falso para outros
  nest-scent           ;; valor mais alto próximo ao ninho
  food-source-number   ;; número (1, 2 ou 3) para identificar as fontes de comida
]

;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-default-shape turtles "bug"

  ;; Criar formigas
  create-turtles population [
    set size 2         ;; mais visível
    set color red      ;; vermelho = não carregando comida
    set is-predator? false
  ]

  ;; Criar predadores
  create-turtles 5 [
    set size 3         ;; Tamanho maior para predadores
    set color black    ;; Cor preta para predadores
    set is-predator? true
  ]

  ;; Configurar patches
  setup-patches
  setup-obstacles       ;; Adiciona obstáculos

  reset-ticks
end

to setup-patches
  ask patches [
    setup-nest
    setup-food
    recolor-patch
  ]
end

to setup-nest  ;; patch procedure
  set nest? (distancexy 0 0) < 5
  set nest-scent 200 - distancexy 0 0
end

to setup-food  ;; patch procedure
  if (distancexy (0.6 * max-pxcor) 0) < 5 [
    set food-source-number 1
  ]
  if (distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 5 [
    set food-source-number 2
  ]
  if (distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 5 [
    set food-source-number 3
  ]
  if food-source-number > 0 [
    set food one-of [1 2]
  ]
end

to setup-obstacles
  ask patches [
    if random 100 < 5 [ ;; 5% dos patches serão obstáculos
      set pcolor grey
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;

to go
  ;; Formigas realizam suas tarefas
  ask turtles with [is-predator? = false] [
    ifelse color = red [
      look-for-food
    ] [
      return-to-nest
    ]
    wiggle
    move
  ]

  ;; Predadores caçam formigas
  ask turtles with [is-predator? = true] [
    hunt
  ]

  ;; Difusão e evaporação do feromônio
  diffuse chemical (diffusion-rate / 100)
  ask patches [
    set chemical chemical * (100 - evaporation-rate) / 100
    recolor-patch
  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Movement procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move
  let target-patch one-of patches in-cone 2 30 with [pcolor != grey]  ;; Evitar obstáculos
  if target-patch != nobody [
    move-to target-patch
  ]
end

to wiggle
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
  
  ;; Verificar se a tartaruga está tentando ir para um obstáculo
  let next-patch patch-ahead 1
  if next-patch != nobody and [pcolor] of next-patch = grey [
    rt 180 ;; Se o patch à frente for um obstáculo, vira 180 graus
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Nest and food procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to return-to-nest
  ifelse nest? [
    set color red
    rt 180
  ] [
    set chemical chemical + 60
    uphill-nest-scent
    let next-patch patch-ahead 1
    if next-patch != nobody and [pcolor] of next-patch = grey [ 
      rt 180 ;; Redireciona caso haja obstáculo
    ]
  ]
end

to look-for-food
  if food > 0 [
    set color orange + 1
    set food food - 1
    rt 180
    stop
  ]
  if (chemical >= 0.05) and (chemical < 2) [
    uphill-chemical
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Predator behavior ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to hunt
  ;; Tentar encontrar uma formiga
  let prey one-of turtles with [is-predator? = false]
  if prey != nobody [
    face prey
    move-to prey
    ;; Tentativa de capturar a formiga
    if distance prey < 1 [
      if random 100 < 5 [ ;; Apenas 5% de chance de capturar
        ask prey [ die ]  ;; Remove a formiga do ambiente
      ]
    ]
  ] 
  ;; Se não encontrar formigas, move-se aleatoriamente
  if prey = nobody [
    wiggle
    move
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helper procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to recolor-patch
  if pcolor = grey [ stop ]  ;; Não altera a cor dos obstáculos
  ifelse nest? [
    set pcolor violet
  ] [
    ifelse food > 0 [
      if food-source-number = 1 [ set pcolor cyan ]
      if food-source-number = 2 [ set pcolor sky ]
      if food-source-number = 3 [ set pcolor blue ]
    ] [
      set pcolor scale-color green chemical 0.1 5
    ]
  ]
end

to uphill-chemical
  let scent-ahead chemical-scent-at-angle 0
  let scent-right chemical-scent-at-angle 45
  let scent-left chemical-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead) [
    ifelse scent-right > scent-left [
      rt 45
    ] [
      lt 45
    ]
  ]
end

to uphill-nest-scent
  let scent-ahead nest-scent-at-angle 0
  let scent-right nest-scent-at-angle 45
  let scent-left nest-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead) [
    ifelse scent-right > scent-left [
      rt 45
    ] [
      lt 45
    ]
  ]
end

to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [chemical] of p
end

to-report nest-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [nest-scent] of p
end
