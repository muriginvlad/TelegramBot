//
//  DefaultBotHandlers.swift
//  
//
//  Created by Vladislav on 24.03.2022.
//

import Foundation
import Vapor
import telegram_vapor_bot

final class DefaultBotHandlers {

    static let share = DefaultBotHandlers()
    
    private let tgApi: String = "5110668200:AAG8CqcfPz4tMs700J6cmdZyVhw9qPUkDTQ"
    
    func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        defaultHandler(app: app, bot: bot)
        commandPingHandler(app: app, bot: bot)
        commandShowButtonsHandler(app: app, bot: bot)
        buttonsActionHandler(app: app, bot: bot)
        commandGetLincFileHandler(app: app, bot: bot)
    }

    
    /// add handler for all messages unless command "/ping"
    private func defaultHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: (.all && !.command.names(["/ping"]) && !.photo && !.document)) { update, bot in
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id),
                                                    text: "Здорово петух"
            )
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }

    private func commandPingHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/ping"]) { update, bot in
            try update.message?.reply(text: "понг", bot: bot)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private func commandGetLincFileHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        
        let handler = TGMessageHandler(filters: (.photo || .document)) { update, bot in

            if let documentID =  update.message?.document?.fileId {
                try? bot.getFile(params: TGGetFileParams (fileId: documentID)) .whenSuccess ({ file in
                    guard let filePath = file.filePath else {
                        return
                    }
                    let url = "https://api.telegram.org/file/bot\(self.tgApi)/\(filePath)"
                    
                    self.linkShortening(urlString: url) { data in
                        let text = "Ссылка на фото: \(url)"
                        try? update.message?.reply(text: text, bot: bot)
                    }
                })
            }
            
            if let photoID = update.message?.photo?.last?.fileId {
                try? bot.getFile(params: TGGetFileParams (fileId: photoID)) .whenSuccess ({ file in
                    guard let filePath = file.filePath else {
                        return
                    }

                    let url = "https://api.telegram.org/file/bot\(self.tgApi)/\(filePath)"
                    self.linkShortening(urlString: url) { url in
                        let text = "Ссылка на фото: \(url)"
                        try? update.message?.reply(text: text, bot: bot)
                    }
                })
            }
        }
        bot.connection.dispatcher.add(handler)
    }
        
    /// add handler for command "/show_buttons" - show message with buttons
    private func commandShowButtonsHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/show_buttons"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            let buttons: [[TGInlineKeyboardButton]] = [
                [.init(text: "Кнопка", callbackData: "press 1"), .init(text: "Кнопка", callbackData: "press 2")]
            ]
            let keyboard: TGInlineKeyboardMarkup = .init(inlineKeyboard: buttons)
            let params: TGSendMessageParams = .init(chatId: .chat(userId),
                                                    text: "Нажми на кнопку, петух!",
                                                    replyMarkup: .inlineKeyboardMarkup(keyboard))
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    /// add two handlers for callbacks buttons
    private func buttonsActionHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCallbackQueryHandler(pattern: "press 1") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try bot.answerCallbackQuery(params: params)
        }

        let handler2 = TGCallbackQueryHandler(pattern: "press 2") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try bot.answerCallbackQuery(params: params)
        }

        bot.connection.dispatcher.add(handler)
        bot.connection.dispatcher.add(handler2)
    }
    
    
    // Вспомогательные функции
    private func linkShortening(urlString: String, closure:  @escaping ((String) -> Void)) {
        DataFetcher.share.getShortURL(urlString: urlString) { data in
            closure(data)
        }
    }
}
