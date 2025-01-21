<?php
namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use Tests\Fixtures\FixtureWebklexMessage;
use Webklex\PHPIMAP\Attachment;
use Webklex\PHPIMAP\ClientManager;
use Webklex\PHPIMAP\Exceptions\AuthFailedException;
use Webklex\PHPIMAP\Exceptions\ConnectionFailedException;
use Webklex\PHPIMAP\Exceptions\ImapBadRequestException;
use Webklex\PHPIMAP\Exceptions\ImapServerErrorException;
use Webklex\PHPIMAP\Exceptions\InvalidMessageDateException;
use Webklex\PHPIMAP\Exceptions\MaskNotFoundException;
use Webklex\PHPIMAP\Exceptions\MessageContentFetchingException;
use Webklex\PHPIMAP\Exceptions\ResponseException;
use Webklex\PHPIMAP\Exceptions\RuntimeException;
use Webklex\PHPIMAP\Message;

class WebklexMessage1Test extends FixtureWebklexMessage {

    /**
     * @throws RuntimeException
     * @throws MessageContentFetchingException
     * @throws ResponseException
     * @throws ImapBadRequestException
     * @throws InvalidMessageDateException
     * @throws ConnectionFailedException
     * @throws \ReflectionException
     * @throws ImapServerErrorException
     * @throws AuthFailedException
     * @throws MaskNotFoundException
     */
    public function testMessage1() {
        $message = $this->getFixture("message-1.eml");

        self::assertSame("☆第132号　「ガーデン&エクステリア」専門店のためのＱ&Ａサロン　【月刊エクステリア・ワーク】", (string)$message->subject);

        $attachments = $message->getAttachments();

        self::assertSame(1, $attachments->count());

        $attachment = $attachments->first();
        self::assertSame("☆第132号　「ガーデン&エクステリア」専門店のためのＱ&Ａサロン　【月刊エクステリア・ワーク】", $attachment->filename);
        self::assertSame("☆第132号　「ガーデン&エクステリア」専門店のためのＱ&Ａサロン　【月刊エクステリア・ワーク】", $attachment->name);
    }

    /**
     * @throws RuntimeException
     * @throws MessageContentFetchingException
     * @throws ResponseException
     * @throws ImapBadRequestException
     * @throws InvalidMessageDateException
     * @throws ConnectionFailedException
     * @throws \ReflectionException
     * @throws ImapServerErrorException
     * @throws AuthFailedException
     * @throws MaskNotFoundException
     */
    public function testMessage1B() {
        $message = $this->getFixture("message-1b.eml");

        self::assertSame("386 - 400021804 - 19., Heiligenstädter Straße 80 - 0819306 - Anfrage Vergabevorschlag", (string)$message->subject);

        $attachments = $message->getAttachments();

        self::assertSame(1, $attachments->count());

        $attachment = $attachments->first();
        //self::assertSame("2021_Mängelliste_0819306.xlsx", $attachment->description);
        self::assertSame("2021_Mängelliste_0819306.xlsx", $attachment->filename);
        //self::assertSame("2021_Mängelliste_0819306.xlsx", $attachment->name);
    }

    /**
     * @throws RuntimeException
     * @throws MessageContentFetchingException
     * @throws ResponseException
     * @throws ImapBadRequestException
     * @throws ConnectionFailedException
     * @throws InvalidMessageDateException
     * @throws ImapServerErrorException
     * @throws AuthFailedException
     * @throws \ReflectionException
     * @throws MaskNotFoundException
     */
    public function testMessage1Symbols() {
        $message = $this->getFixture("message-1symbols.eml");

        $attachments = $message->getAttachments();

        self::assertSame(1, $attachments->count());

        /** @var Attachment $attachment */
        $attachment = $attachments->first();
        // self::assertSame("Checkliste 10.,DAVIDGASSE 76-80;2;2.pdf", $attachment->description);
        // self::assertSame("Checkliste 10.,DAVIDGASSE 76-80;2;2.pdf", $attachment->name);
        self::assertSame("Checkliste 10.,DAVIDGASSE 76-80;2;2.pdf", $attachment->filename);
    }

}