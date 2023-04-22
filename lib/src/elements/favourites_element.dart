import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_app/main.dart';
import 'package:event_app/src/constants.dart';
import 'package:event_app/src/model/event.dart';
import 'package:event_app/src/pages/event_detail_page.dart';
import 'package:event_app/src/utility/formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class FavouritesElement extends StatefulWidget {
  FavouritesElement({
    Key? key,
    required this.event,
    required this.callback,
  }) : super(key: key);

  Event event;

  // used to refresh ancestor page if changes on event are made
  final Future Function() callback;

  @override
  _FavouritesElementState createState() => _FavouritesElementState();
}

class _FavouritesElementState extends State<FavouritesElement> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late bool toggleButtonFavourite;
  late Event event;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    if (mounted) {
      setState(() {
        toggleButtonFavourite =
            appState.user.favoriteEventIds.contains(event.eventId);
        likeCount = widget.event.likeCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: Constants.backgroundColorSecondary,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 250),
                reverseDuration: const Duration(milliseconds: 250),
                child: EventDetailsPage(event: event, key: null),
                fullscreenDialog: true,
              )).then((updatedEvent) async {
            await widget.callback();
            if (mounted) {
              setState(() {
                widget.event = updatedEvent;
                toggleButtonFavourite =
                    appState.user.favoriteEventIds.contains(event.eventId);
                likeCount = widget.event.likeCount;
              });
            }
          });
        },
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 2 / 5,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: event.image == null
                        ? Image(
                            image:
                                Image.asset('assets/images/Stand_By.jpg').image,
                            colorBlendMode: BlendMode.color,
                          )
                        : CachedNetworkImage(
                            imageUrl: event.image!,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(
                              color: Constants.themeColor,
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
                      child: Card(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        color: Constants.backgroundColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
                          child: InkResponse(
                            radius: 25,
                            // like or dislike event
                            onTap: () async {
                              if (appState.offlineMode == true ||
                                  appState.serverAlive == false) return;

                              int newValue = -1;

                              try {
                                newValue = await network
                                    .toggleFavoriteEvent(widget.event.eventId);
                              } catch (e) {
                                if (kDebugMode) {
                                  print(
                                      'Fav toggle not possible because of unreachable network or server!');
                                }
                                return;
                              }

                              if (newValue != -1) {
                                if (mounted) {
                                  setState(() {
                                    toggleButtonFavourite =
                                        !toggleButtonFavourite;
                                  });
                                }
                                if (toggleButtonFavourite) {
                                  appState.user.favoriteEventIds
                                      .add(widget.event.eventId);
                                } else {
                                  appState.user.favoriteEventIds
                                      .remove(widget.event.eventId);
                                }

                                // set new likeCount
                                widget.event.likeCount = newValue;
                                await appState.sqliteDbUsers
                                    .updateUser(appState.user);
                                await appState.sqliteDbEvents
                                    .updateEvent(widget.event);
                                if (mounted) {
                                  setState(() {
                                    likeCount = widget.event.likeCount;
                                    widget.callback();
                                  });
                                }
                              }
                            },
                            child: Icon(
                              toggleButtonFavourite
                                  ? Icons.star_rate
                                  : Icons.star_outline,
                              color: Constants.iconColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 2 / 5,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Constants.themeColor,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(4, 12, 4, 12),
                        child: Text(
                          Formatter.getDateFormatted(
                                  event.startTimestamp, 'dd.MM ')
                              .toString(),
                          textAlign: TextAlign.center,
                          style: const MyTextStyle(
                            cColor: Constants.mainTextColorLight,
                            cFontSize: 20,
                            cFontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 8, 0, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.eventName,
                              style: const MyTextStyle(
                                cColor: Constants.mainTextColorDark,
                                cFontSize: 14,
                                cFontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              event.description,
                              style: const MyTextStyle(
                                cColor: Constants.secondaryTextColorDark,
                                cFontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
