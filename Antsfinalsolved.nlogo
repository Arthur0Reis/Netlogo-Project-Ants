globals [
  success-rate  ;; Taxa de sucesso do predador ao tentar comer uma formiga
]

patches-own [
  chemical             ;; quantidade de feromônio no patch
  food                 ;; quantidade de comida no patch (0, 1 ou 2)
  nest?                ;; verdadeiro para patches do ninho, falso para outros
  nest-scent           ;; valor mais alto próximo ao ninho
  food-source-number   ;; número (1, 2 ou 3) para identificar as fontes de comida
]

turtles-own [
  is-predator?         ;; Indica se é um predador (true) ou uma formiga (false)
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-default-shape turtles "bug"

  ;; Configurar taxa de sucesso do predador
  set success-rate 5  ;; 50% de chance de sucesso ao comer uma formiga

  ;; Criar formigas
  create-turtles population [
    set size 2         ;; Mais visível
    set color red      ;; Cor vermelha = não carregando comida
    set is-predator? false
  ]

  ;; Criar predador
  create-turtles 1 [
    set size 3         ;; Maior que as formigas
    set color green    ;; Predador será verde
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

to setup-nest
  set nest? (distancexy 0 0) < 5
  set nest-scent 200 - distancexy 0 0
end

to setup-food
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
    if random 100 < 2 [ ;; 5% dos patches serão obstáculos
      set pcolor grey
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; Formigas realizam suas tarefas
  ask turtles with [is-predator? = false] [
    ifelse color = red [
      look-for-food
    ] [
      return-to-nest
    ]
    avoid-obstacles
    fd 1
  ]

  ;; Predador caça formigas
  ask turtles with [is-predator? = true] [
    hunt
    avoid-obstacles
    fd 1
  ]

  ;; Atualizar patches
  diffuse chemical (diffusion-rate / 100)
  ask patches [
    set chemical chemical * (100 - evaporation-rate) / 100
    recolor-patch
  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Movement adjustments ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to avoid-obstacles
  let next-patch patch-ahead 1
  if next-patch = nobody or [pcolor] of next-patch = grey [
    rt random 180 ;; Ajusta direção aleatoriamente para evitar bloqueios
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;; Formiga Actions ;;;
;;;;;;;;;;;;;;;;;;;;;;

to look-for-food
  if food > 0 [
    set color orange
    set food food - 1
    rt 180
    stop
  ]
  if (chemical >= 0.05) and (chemical < 2) [
    uphill-chemical
  ]
end

to return-to-nest
  ifelse nest? [
    set color red
    rt 180
  ] [
    set chemical chemical + 60
    uphill-nest-scent
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;; Predador Actions ;;;
;;;;;;;;;;;;;;;;;;;;;;

to hunt
  let target one-of turtles with [is-predator? = false]  ;; Seleciona uma formiga aleatória
  if target != nobody [
    face target
    move-to target
    if distance target < 1 [
      if random 100 < success-rate [  ;; Determina se o predador terá sucesso
        ask target [ die ]  ;; Remove a formiga
        set population population - 1  ;; Atualiza a população de formigas
      ]
    ]
  ]
  if target = nobody [
    rt random 45
    lt random 45
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helper procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to recolor-patch
  if pcolor = grey [ stop ]
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
