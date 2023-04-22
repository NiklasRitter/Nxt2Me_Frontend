import 'package:event_app/src/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityInput extends StatefulWidget {
  /// widget to determine maximum views of event
  const QuantityInput({Key? key, required this.controller}) : super(key: key);

  final TextEditingController controller;

  @override
  _QuantityInputState createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  /// available steps for maximum views
  List<String> steps = ["10", "20", "50", "100", "unlimited"];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        InkWell(
          child: const Icon(
            Icons.remove,
            size: 24.0,
            color: Constants.themeColor,
          ),
          // click on minus button
          onTap: () {
            int currentValue = steps.indexOf(widget.controller.text);

            // if currentValue is in steps set to one step smaller
            if (currentValue > 0) {
              if (mounted) {
                setState(() {
                  widget.controller.text = steps[currentValue - 1].toString();
                });
              }
            } else if (currentValue == -1) {
              try {

                currentValue = int.parse(widget.controller.text);

                // get closest smaller value from steps
                for (int i = steps.length - 2; i >= 0; i--) {
                  int step = int.parse(steps[i]);
                  if (step < currentValue) {
                    currentValue = step;
                    break;
                  }
                }
                // if controller value is smaller than smallest
                // step set to minimum
                if (!steps.contains(currentValue.toString())) {
                  if (mounted) {
                    setState(() {
                      widget.controller.text = steps.first;
                    });
                  }
                } else {
                  if (mounted) {
                    setState(() {
                      widget.controller.text = currentValue.toString();
                    });
                  }
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    widget.controller.text = steps.first.toString();
                  });
                }
              }
            }
          },
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            decoration: const InputDecoration(
              focusedBorder: InputBorder.none,
              border: InputBorder.none
            ),
            style: const MyTextStyle(),
            textAlign: TextAlign.center,
            controller: widget.controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        InkWell(
          child: const Icon(
            Icons.add,
            size: 24.0,
            color: Constants.themeColor,
          ),
          // click on plus button
          onTap: () {
            int currentValue = steps.indexOf(widget.controller.text);

            // if currentValue is in steps (except unlimited) set to one step higher
            if (currentValue >= 0 && currentValue < steps.length - 1) {
              if (mounted) {
                setState(() {
                  widget.controller.text = steps[currentValue + 1].toString();
                });
              }
            } else if (currentValue == -1) {
              try {
                currentValue = int.parse(widget.controller.text);

                // get closest bigger value from steps
                for (int i = 0; i < steps.length - 1; i++) {
                  int step = int.parse(steps[i]);
                  if (step > currentValue) {
                    currentValue = step;
                    break;
                  }
                }
                // if controller value is bigger than biggest step
                if (!steps.contains(currentValue.toString())) {
                  if (mounted) {
                    setState(() {
                      widget.controller.text = steps.last;
                    });
                  }
                } else {
                  if (mounted) {
                    setState(() {
                      widget.controller.text = currentValue.toString();
                    });
                  }
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    widget.controller.text = steps.last.toString();
                  });
                }
              }
            }
          },
        ),
      ],
    );
  }
}
